# app/services/game_generator.rb
class GameGenerator
  PLAYER_COUNT = 8

  def initialize(game)
    @game = game
    @available_cards = load_cards
    @catastrophe_bias_tags = game.catastrophe&.card_bias_tags.to_s.split(", ").map(&:strip).reject(&:empty?)
  end

  def call(player_count = PLAYER_COUNT)
    @game.game_events.delete_all  # Очищаем лог перед перегенерацией

    # Если игроки уже существуют (из лобби) — используем их, только чистим карты
    # Если нет — создаём новых (обратная совместимость)
    existing = @game.players.reload
    if existing.any?
      existing.each { |p| p.player_cards.delete_all; p.player_action_cards.delete_all }
      players = existing.to_a
    else
      players = create_players(player_count)
    end

    setup_bunker(players.count)

    # Этап 1: Уникальные профессии (с учётом биаса катастрофы)
    assign_unique_professions(players)

    # Этап 2: Уникальные карты действий (каждая — одна на партию)
    assign_unique_action_cards(players)

    # Этап 3: Data-driven синергии через SynergyEngine (30+ типов)
    engine = SynergyEngine.new(@available_cards, @catastrophe_bias_tags)
    @applied_synergies = engine.apply(players)

    # Убираем из пула карты, выданные синергиями (чтобы не дублировались)
    remove_used_cards_from_pool(players)

    # Этап 4: Балансированная раздача оставшихся карт
    %w[health luggage hobby fact phobia].each { |cat| assign_balanced_cards(players, cat) }

    # Этап 5: Пост-генерационные проверки баланса
    ensure_party_balance(players)
  end

  private

  # ============================================================
  # SETUP
  # ============================================================

  def load_cards
    Card.all.group_by(&:category)
  end

  def setup_bunker(player_count)
    capacity = (player_count / 2).to_i

    duration_roll = rand(1..100)
    duration = case duration_roll
    when 1..50 then 5
    when 51..70 then 2
    when 71..90 then 10
    when 91..95 then 15
    when 96..99 then 20
    else 50
    end

    selected_features = BunkerFeature.order("RANDOM()").limit(2)
    features_data = selected_features.map { |f| { name: f.name, description: f.description } }
    threat = Threat.order("RANDOM()").first

    @game.update!(
      bunker_capacity: capacity,
      bunker_duration: duration,
      bunker_supplies: [ "Запасов еды хватит на весь срок", "Еды хватит только на половину срока", "Критический дефицит продовольствия" ].sample,
      bunker_size: [ "Просторный", "Тесный", "Средний" ].sample,
      bunker_features: features_data,
      threat: threat,
      current_round: 1,
      status: "in_progress"
    )
  end

  # ============================================================
  # СОЗДАНИЕ ИГРОКОВ
  # ============================================================

  def create_players(count)
    genders = [ "Мужчина", "Мужчина", "Женщина", "Женщина" ]
    (count - 4).times { genders << [ "Мужчина", "Женщина" ].sample }
    genders.shuffle!

    Array.new(count) do |i|
      @game.players.create!(gender: genders[i])
    end
  end

  # ============================================================
  # РАЗДАЧА ПРОФЕССИЙ (с учётом биаса катастрофы)
  # ============================================================

  def assign_unique_professions(players)
    pool = @available_cards["profession"].dup

    # Катастрофа повышает шанс выпадения релевантных профессий:
    # Берём 30% слотов под биас-профессии, остальные — рандом
    if @catastrophe_bias_tags.any?
      biased = pool.select { |c| tags_overlap?(c.tags, @catastrophe_bias_tags) }.shuffle
      neutral = pool.reject { |c| tags_overlap?(c.tags, @catastrophe_bias_tags) }.shuffle

      # Гарантируем минимум 1-2 релевантных профессии (если доступны)
      biased_count = [ (players.count * 0.3).ceil, biased.count ].min
      selected = biased.first(biased_count) + neutral
      selected = selected.uniq.first(players.count)
    else
      selected = pool.sample(players.count)
    end

    players.zip(selected).each do |player, card|
      add_card_to_player(player, card) if card
    end
  end

  # ============================================================
  # УНИКАЛЬНЫЕ ACTION CARDS (Баг-фикс: каждая карта — одна на партию)
  # ============================================================

  def assign_unique_action_cards(players)
    available_count = ActionCard.count
    # Гарантируем уникальность: limit не больше, чем есть карт
    action_cards = ActionCard.order("RANDOM()").limit([ players.count, available_count ].min)
    players.zip(action_cards).each do |player, ac|
      PlayerActionCard.create!(player: player, action_card: ac) if ac
    end
  end

  # Синергии обрабатываются через SynergyEngine (см. app/services/synergy_engine.rb)

  # ============================================================
  # БАЛАНСИРОВАННАЯ РАЗДАЧА КАРТ
  # ============================================================

  def assign_balanced_cards(players, category)
    cards_pool = @available_cards[category]&.dup || []
    return if cards_pool.empty?

    # Перемешиваем порядок игроков — иначе первый всегда получает "лучшую" карту
    players.shuffle.each do |player|
      next if player_has_category?(player, category)

      card = weighted_random_card(cards_pool, player)
      next unless card

      add_card_to_player(player, card)

      # "Идеально здоров" можно дублировать, остальные — нет
      unless has_tag?(card.tags, "healthy")
        cards_pool.delete(card)
      end
    end
  end

  # Взвешенный рандом с экспоненциальным затуханием.
  #
  # Вместо "выбрать top-N ближайших к 0" — КАЖДАЯ карта имеет шанс,
  # но карты ближе к балансу более вероятны.
  #
  # Формула: probability = e^(-distance * DECAY)
  #   distance 0 (идеал) → вероятность 1.0
  #   distance 1          → вероятность 0.74
  #   distance 2          → вероятность 0.55
  #   distance 4          → вероятность 0.30
  #   distance 6          → вероятность 0.17
  #
  # DECAY=0.3 — баланс между разнообразием и весовой логикой.
  BALANCE_DECAY = 0.3

  def weighted_random_card(cards_pool, player)
    return nil if cards_pool.empty?

    current_weight = player.cards.sum(&:weight)

    weighted = cards_pool.map do |card|
      distance = (current_weight + card.weight).abs
      prob = Math.exp(-distance * BALANCE_DECAY)

      # Катастрофа-биас: +30% вероятность для релевантных карт
      if @catastrophe_bias_tags.any? && tags_overlap?(card.tags, @catastrophe_bias_tags)
        prob *= 1.3
      end

      [ card, prob ]
    end

    # Взвешенный выбор
    total = weighted.sum(&:last)
    return cards_pool.sample if total == 0

    point = rand * total
    cumulative = 0.0
    weighted.shuffle.each do |card, prob|  # shuffle чтобы при равных весах не было порядка
      cumulative += prob
      return card if cumulative >= point
    end

    cards_pool.sample # fallback
  end

  # Убираем из available_cards карты, которые уже выданы синергиями
  def remove_used_cards_from_pool(players)
    used_card_ids = players.flat_map { |p| p.cards.pluck(:id) }.to_set
    @available_cards.each do |category, cards|
      cards.reject! { |c| used_card_ids.include?(c.id) } unless category == "profession"
    end
  end

  # ============================================================
  # ПОСТ-ГЕНЕРАЦИОННЫЕ ПРОВЕРКИ БАЛАНСА
  # ============================================================

  def ensure_party_balance(players)
    players.each(&:reload)

    ensure_medic_exists(players)
    ensure_severe_illness(players)
    ensure_no_extreme_weight(players)
  end

  # Гарантия: минимум 1 медик/психиатр/генетик (tier S/A с тегом medical или mental_health)
  def ensure_medic_exists(players)
    has_medic = players.any? { |p|
      prof = p.profession
      next false unless prof
      (has_tag?(prof.tags, "medical") || has_tag?(prof.tags, "mental_health")) &&
        %w[S A].include?(prof.tier&.strip)
    }

    unless has_medic
      # Заменяем профессию самого слабого игрока (наименьший вес карт) на медика
      weakest = players.min_by { |p| p.cards.sum(&:weight) }
      medic_card = @available_cards["profession"]&.select { |c|
        (has_tag?(c.tags, "medical") || has_tag?(c.tags, "mental_health")) &&
          %w[S A].include?(c.tier&.strip)
      }&.sample

      if medic_card && weakest
        old_prof_pc = weakest.player_cards.joins(:card).find_by(cards: { category: "profession" })
        old_prof_pc&.update!(card: medic_card)
      end
    end
  end

  # Гарантия: минимум 1 тяжёлая болезнь (severity 60%+) для драмы
  def ensure_severe_illness(players)
    has_severe = players.any? { |p|
      p.player_cards.joins(:card).where(cards: { category: "health" }).any? { |pc|
        pc.severity.to_i >= 60
      }
    }

    unless has_severe
      # Находим игрока с болезнью (не здоровый, не необследованный) и повышаем severity
      sick_pcs = PlayerCard.joins(:card, :player)
        .where(players: { game_id: @game.id }, cards: { category: "health" })
        .where.not("cards.tags LIKE ?", "%healthy%")
        .where.not("cards.tags LIKE ?", "%unknown%")

      pc_to_boost = sick_pcs.sample
      pc_to_boost&.update!(severity: rand(12..16) * 5) # 60-80%
    end
  end

  # Гарантия: ни у кого суммарный вес не ниже -8
  def ensure_no_extreme_weight(players)
    players.each do |player|
      total = player.cards.sum(&:weight)
      next if total >= -8

      # Находим самую слабую карту и заменяем на что-то лучше
      worst_pc = player.player_cards.joins(:card)
        .where.not(cards: { category: "profession" }) # профессию не трогаем
        .order("cards.weight ASC").first

      next unless worst_pc

      better_card = @available_cards[worst_pc.card.category]&.select { |c|
        c.weight > worst_pc.card.weight
      }&.sample

      worst_pc.update!(card: better_card) if better_card
    end
  end

  # ============================================================
  # УТИЛИТЫ
  # ============================================================

  # Точное совпадение тега (НЕ подстрока!). "sea" НЕ матчит "seasonal".
  def has_tag?(tags_string, tag)
    tags_string.to_s.split(/,\s*/).map(&:strip).include?(tag)
  end

  # Проверка: есть ли хотя бы один из тегов
  def has_any_tag?(tags_string, tag_list)
    parsed = tags_string.to_s.split(/,\s*/).map(&:strip)
    tag_list.any? { |t| parsed.include?(t) }
  end

  # Проверка: пересекаются ли теги карты с набором тегов
  def tags_overlap?(card_tags, bias_tags)
    parsed = card_tags.to_s.split(/,\s*/).map(&:strip)
    (parsed & bias_tags).any?
  end

  # Найти игрока с определённым тегом профессии
  def find_player_with_tag(players, tag)
    players.find { |p| has_tag?(p.profession&.tags, tag) }
  end

  # Игроки, у которых ещё нет карты данной категории
  def available_for_category(players, category, except: nil)
    players.reject { |p| p == except || player_has_category?(p, category) }
  end

  # Проверка: есть ли у игрока карта данной категории
  def player_has_category?(player, category)
    player.cards.any? { |c| c.category == category }
  end

  # Добавляем карту игроку. Severity: 10%-95% (ИСПРАВЛЕНО: было до 90%)
  def add_card_to_player(player, card)
    return unless card

    severity = nil
    if card.category == "health" && !has_tag?(card.tags, "healthy") && !has_tag?(card.tags, "unknown")
      severity = rand(2..19) * 5 # 10% — 95%
    end

    PlayerCard.create!(player: player, card: card, severity: severity, revealed: false)
    player.reload
  end
end
