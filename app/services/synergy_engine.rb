# app/services/synergy_engine.rb
#
# Data-driven движок синергий. Все синергии описаны как данные в REGISTRY.
# GameGenerator вызывает SynergyEngine.apply(players, cards_pool, catastrophe_tags)
# и получает список сработавших синергий.
#
# Типы синергий:
#   :pair         — два игрока с комплементарными профессиями → дать карту одному
#   :inject       — профессия/хобби одного → дать карту ДРУГОМУ игроку
#   :self_irony   — дать конфликтующую карту самому себе (ирония)
#   :catastrophe  — если катастрофа содержит тег → дать карту рандомному игроку
#   :hobby_boost  — хобби → дать связанный багаж себе
#   :cross_fact   — дать связанные факты ДВУМ разным игрокам
#
class SynergyEngine
  # Максимум синергий за партию (% от игроков)
  MAX_SYNERGY_RATIO = 0.6 # 60% от числа игроков, т.е. ~5 для 8 игроков

  REGISTRY = [
    # ================================================================
    # ПАРНЫЕ ПРОФЕССИИ
    # ================================================================
    {
      name: "Медцентр", type: :pair,
      trigger: { profession_tag: "medical" },
      partner: { profession_tag: "chemical" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[medical healing]
    },
    {
      name: "Ферма", type: :pair,
      trigger: { profession_tag: "agriculture" },
      partner: { profession_tag: "food" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[food farming]
    },
    {
      name: "Оборона", type: :pair,
      trigger: { profession_tag: "security" },
      partner: { profession_tag: "security" }, # второй с тем же тегом
      give_to: :trigger, give_category: "luggage",
      give_tags: %w[weapon]
    },
    {
      name: "Лаборатория", type: :pair,
      trigger: { profession_tag: "science" },
      partner: { profession_tag: "technical" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[technical software]
    },
    {
      name: "Бригада", type: :pair,
      trigger: { profession_tag: "technical" },
      partner: { profession_tag: "building" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[technical building]
    },
    {
      name: "Контрразведка", type: :pair,
      trigger: { profession_tag: "security" },
      partner: { profession_tag: "software" },
      give_to: :partner, give_category: "fact",
      give_tags: %w[info technical]
    },
    {
      name: "Дипломатия", type: :pair,
      trigger: { profession_tag: "mental_health" },
      partner: { profession_tag: "social" },
      give_to: :partner, give_category: "hobby",
      give_tags: %w[social mental_health]
    },
    {
      name: "Егеря", type: :pair,
      trigger: { profession_tag: "hunting" },
      partner: { profession_tag: "nature" },
      give_to: :trigger, give_category: "hobby",
      give_tags: %w[survival hunting]
    },

    # ================================================================
    # ПРОФЕССИЯ ОДНОГО → КАРТА ДРУГОМУ (конфликты и связи)
    # ================================================================
    {
      name: "Детектив и маньяк", type: :inject,
      trigger: { profession_tag: "security" },
      give_category: "fact", give_tags: %w[criminal danger]
    },
    {
      name: "Врач и антипрививочник", type: :inject,
      trigger: { profession_tag: "medical" },
      give_category: "phobia", give_card_name: "Иатрофобия"
    },
    {
      name: "Психолог и параноик", type: :inject,
      trigger: { profession_tag: "mental_health" },
      give_category: "health", give_card_name: "Мания преследования"
    },
    {
      name: "Врач + Излечимый больной", type: :inject,
      trigger: { profession_tag: "medical" },
      give_category: "health", give_filter: :curable_disease
    },
    {
      name: "Психолог + Тяжёлая фобия", type: :inject,
      trigger: { profession_tag: "mental_health" },
      give_category: "phobia", give_tags: %w[panic]
    },
    {
      name: "Производитель алкоголя + Алкоголик", type: :inject,
      trigger: { profession_tag: "alcohol" },
      give_category: "health", give_card_name: "Алкоголизм"
    },
    {
      name: "Химик + Наркозависимый", type: :inject,
      trigger: { any_profession_tag: %w[chemical science] },
      give_category: "health", give_card_name_contains: "Зависимость"
    },
    {
      name: "Священник и сектант", type: :inject,
      trigger: { profession_tag: "social" },
      give_category: "fact", give_tags: %w[cult mental]
    },

    # ================================================================
    # ПРОФЕССИЯ → ДАТЬ ПРЕДМЕТ (себе или партнёру)
    # ================================================================
    {
      name: "Фермер + Семена", type: :inject,
      trigger: { profession_tag: "agriculture" },
      give_category: "luggage", give_tags: %w[farming food]
    },
    {
      name: "Инженер + Инструменты", type: :inject,
      trigger: { profession_tag: "technical" },
      give_category: "luggage", give_tags: %w[repair technical]
    },
    {
      name: "Повар + Еда", type: :inject,
      trigger: { profession_tag: "food" },
      give_category: "luggage", give_tags: %w[food]
    },
    {
      name: "Военный + Оружие", type: :inject,
      trigger: { profession_tag: "security" },
      give_to_self_chance: 50, # 50% себе, 50% другому
      give_category: "luggage", give_tags: %w[weapon]
    },
    {
      name: "Хакер + Ноутбук", type: :inject,
      trigger: { profession_tag: "software" },
      give_to_self_chance: 50,
      give_category: "luggage", give_card_name_contains: "Ноутбук"
    },
    {
      name: "Творческий + Депрессия", type: :inject,
      trigger: { any_profession_tag: %w[art social] },
      give_category: "health", give_card_name_contains: "Депрессия"
    },

    # ================================================================
    # САМОИРОНИЯ (конфликтующая карта самому себе)
    # ================================================================
    {
      name: "Безрукий хирург", type: :self_irony,
      trigger: { profession_tag: "surgery" },
      give_category: "health", give_card_name: "Тремор рук"
    },
    {
      name: "Хакер-технофоб", type: :self_irony,
      trigger: { profession_tag: "software" },
      give_category: "phobia", give_card_name: "Технофобия"
    },
    {
      name: "Клаустрофоб в бункере", type: :self_irony,
      trigger: :random_player,
      give_category: "phobia", give_card_name: "Клаустрофобия"
    },
    {
      name: "Слепой снайпер", type: :self_irony,
      trigger: { profession_tag: "security" },
      give_category: "health", give_tags: %w[disability]
    },
    {
      name: "Нобелевский бомж", type: :self_irony,
      trigger: :random_player,
      give_category: "fact", give_card_name: "Нобелевский лауреат"
      # Второй факт "Бродяжничал" добавится через balanced_cards
    },

    # ================================================================
    # ХОББИ → БАГАЖ (хобби усиливается багажом)
    # ================================================================
    {
      name: "Выживальщик", type: :hobby_boost,
      trigger: { hobby_tag: "survival" },
      give_category: "luggage", give_tags: %w[weapon survival]
    },
    {
      name: "Радист", type: :hobby_boost,
      trigger: { hobby_tag: "communication" },
      give_category: "luggage", give_tags: %w[communication technical]
    },
    {
      name: "Кузнец", type: :hobby_boost,
      trigger: { hobby_tag: "crafting" },
      give_category: "luggage", give_tags: %w[technical building]
    },
    {
      name: "Травник", type: :hobby_boost,
      trigger: { hobby_tag: "nature" },
      give_category: "fact", give_tags: %w[nature survival]
    },
    {
      name: "Пиротехник", type: :hobby_boost,
      trigger: { hobby_tag: "explosive" },
      give_category: "fact", give_tags: %w[combat security]
    },

    # ================================================================
    # КАТАСТРОФА-СПЕЦИФИЧНЫЕ
    # ================================================================
    {
      name: "Ядерное наследие", type: :catastrophe,
      catastrophe_tags: %w[radiation],
      give_category: "luggage", give_card_name_contains: "Гейгер"
    },
    {
      name: "Респиратор", type: :catastrophe,
      catastrophe_tags: %w[radiation chemical],
      give_category: "luggage", give_card_name_contains: "противогаз"
    },
    {
      name: "Страх воды", type: :catastrophe,
      catastrophe_tags: %w[water],
      give_category: "phobia", give_card_name: "Аквафобия"
    },
    {
      name: "Кошмары", type: :catastrophe,
      catastrophe_tags: %w[mental strange],
      give_category: "phobia", give_card_name: "Сомнифобия"
    },
    {
      name: "Тихий ужас", type: :catastrophe,
      catastrophe_tags: %w[communication],
      give_category: "phobia", give_card_name: "Глоссофобия"
    },
    {
      name: "Грибной эксперт", type: :catastrophe,
      catastrophe_tags: %w[nature science],
      give_category: "hobby", give_card_name: "Гидропоника"
    },

    # ================================================================
    # ПЕРЕКРЁСТНЫЕ ФАКТЫ (двум игрокам дать связанные карты)
    # ================================================================
    {
      name: "Шпион среди нас", type: :cross_fact,
      give_both_category: "fact",
      player_a_card_name: "Ранее судим за шпионаж",
      player_b_card_name: "Ранее судим за шпионаж"
    },
    {
      name: "Телепат и параноик", type: :cross_fact,
      give_both_category: "mixed",
      player_a_category: "fact", player_a_card_name: "Телепат",
      player_b_category: "health", player_b_card_name: "Мания преследования"
    },
    {
      name: "Криминал + Отмычки", type: :cross_fact,
      give_both_category: "mixed",
      player_a_category: "fact", player_a_tags: %w[criminal],
      player_b_category: "luggage", player_b_card_name_contains: "отмычек"
    },
  ].freeze

  def initialize(cards_pool, catastrophe_tags = [])
    @cards_pool = cards_pool
    @catastrophe_tags = catastrophe_tags
    @applied = []
  end

  # Главный метод: применяет синергии к игрокам.
  # Возвращает массив имён сработавших синергий.
  def apply(players, max_count: nil)
    max_count ||= (players.count * MAX_SYNERGY_RATIO).ceil

    REGISTRY.shuffle.each do |synergy|
      break if @applied.count >= max_count
      result = process_synergy(synergy, players)
      @applied << synergy[:name] if result
    end

    @applied
  end

  private

  def process_synergy(syn, players)
    case syn[:type]
    when :pair          then apply_pair(syn, players)
    when :inject        then apply_inject(syn, players)
    when :self_irony    then apply_self_irony(syn, players)
    when :catastrophe   then apply_catastrophe(syn, players)
    when :hobby_boost   then apply_hobby_boost(syn, players)
    when :cross_fact    then apply_cross_fact(syn, players)
    else false
    end
  rescue => e
    Rails.logger.warn("Synergy '#{syn[:name]}' failed: #{e.message}")
    false
  end

  # ================================================================
  # ОБРАБОТЧИКИ ТИПОВ
  # ================================================================

  def apply_pair(syn, players)
    trigger_player = find_by_condition(players, syn[:trigger])
    return false unless trigger_player

    # Партнёр — другой игрок с другим тегом (или тем же, но другой человек)
    partner_player = find_by_condition(players, syn[:partner], exclude: trigger_player)
    return false unless partner_player

    receiver = syn[:give_to] == :trigger ? trigger_player : partner_player
    return false if player_has_category?(receiver, syn[:give_category])

    card = find_card(syn)
    return false unless card

    give_card!(receiver, card)
    true
  end

  def apply_inject(syn, players)
    trigger_player = find_by_condition(players, syn[:trigger])
    return false unless trigger_player

    # Определяем получателя
    if syn[:give_to_self_chance] && rand(100) < syn[:give_to_self_chance]
      receiver = trigger_player
    else
      receiver = available_for(players, syn[:give_category], exclude: trigger_player).sample
    end
    return false unless receiver
    return false if player_has_category?(receiver, syn[:give_category])

    card = find_card(syn)
    return false unless card

    give_card!(receiver, card)
    true
  end

  def apply_self_irony(syn, players)
    if syn[:trigger] == :random_player
      trigger_player = available_for(players, syn[:give_category]).sample
    else
      trigger_player = find_by_condition(players, syn[:trigger])
    end
    return false unless trigger_player
    return false if player_has_category?(trigger_player, syn[:give_category])

    card = find_card(syn)
    return false unless card

    give_card!(trigger_player, card)
    true
  end

  def apply_catastrophe(syn, players)
    # Проверяем пересечение тегов катастрофы с требованиями синергии
    return false unless (syn[:catastrophe_tags] & @catastrophe_tags).any?

    receiver = available_for(players, syn[:give_category]).sample
    return false unless receiver

    card = find_card(syn)
    return false unless card

    give_card!(receiver, card)
    true
  end

  def apply_hobby_boost(syn, players)
    trigger_player = players.find { |p|
      hobby = p.cards.find { |c| c.category == "hobby" }
      hobby && has_tag?(hobby.tags, syn[:trigger][:hobby_tag])
    }
    return false unless trigger_player
    return false if player_has_category?(trigger_player, syn[:give_category])

    card = find_card(syn)
    return false unless card

    give_card!(trigger_player, card)
    true
  end

  def apply_cross_fact(syn, players)
    available_a = available_for(players, syn[:player_a_category] || syn[:give_both_category])
    return false if available_a.count < 2

    player_a = available_a.sample
    available_b = available_for(players, syn[:player_b_category] || syn[:give_both_category], exclude: player_a)
    player_b = available_b.sample
    return false unless player_a && player_b

    card_a = find_card_for_cross(syn, :a)
    card_b = find_card_for_cross(syn, :b)
    return false unless card_a && card_b

    give_card!(player_a, card_a)
    give_card!(player_b, card_b)
    true
  end

  # ================================================================
  # ПОИСК КАРТ
  # ================================================================

  def find_card(syn)
    pool = @cards_pool[syn[:give_category]] || []

    if syn[:give_card_name]
      pool.find { |c| c.name == syn[:give_card_name] }
    elsif syn[:give_card_name_contains]
      pool.find { |c| c.name.downcase.include?(syn[:give_card_name_contains].downcase) }
    elsif syn[:give_filter] == :curable_disease
      pool.select { |c| c.is_curable && c.weight < 0 }.sample
    elsif syn[:give_tags]
      matching = pool.select { |c| (parse_tags(c.tags) & syn[:give_tags]).any? }
      matching.any? ? matching.sample : nil
    else
      pool.sample
    end
  end

  def find_card_for_cross(syn, side)
    cat = syn[:"player_#{side}_category"] || syn[:give_both_category]
    pool = @cards_pool[cat] || []

    name = syn[:"player_#{side}_card_name"]
    name_contains = syn[:"player_#{side}_card_name_contains"]
    tags = syn[:"player_#{side}_tags"]

    if name
      pool.find { |c| c.name == name }
    elsif name_contains
      pool.find { |c| c.name.downcase.include?(name_contains.downcase) }
    elsif tags
      pool.select { |c| (parse_tags(c.tags) & tags).any? }.sample
    else
      pool.sample
    end
  end

  # ================================================================
  # ПОИСК ИГРОКОВ
  # ================================================================

  def find_by_condition(players, condition, exclude: nil)
    candidates = exclude ? players.reject { |p| p == exclude } : players

    if condition[:profession_tag]
      candidates.find { |p| has_tag?(p.profession&.tags, condition[:profession_tag]) }
    elsif condition[:any_profession_tag]
      candidates.find { |p|
        condition[:any_profession_tag].any? { |t| has_tag?(p.profession&.tags, t) }
      }
    elsif condition[:hobby_tag]
      candidates.find { |p|
        hobby = p.cards.find { |c| c.category == "hobby" }
        hobby && has_tag?(hobby.tags, condition[:hobby_tag])
      }
    end
  end

  def available_for(players, category, exclude: nil)
    players.reject { |p|
      p == exclude || player_has_category?(p, category)
    }
  end

  # ================================================================
  # УТИЛИТЫ
  # ================================================================

  def player_has_category?(player, category)
    player.cards.any? { |c| c.category == category }
  end

  def has_tag?(tags_string, tag)
    parse_tags(tags_string).include?(tag)
  end

  def parse_tags(tags_string)
    tags_string.to_s.split(/,\s*/).map(&:strip).reject(&:empty?)
  end

  def give_card!(player, card)
    severity = nil
    if card.category == "health" && !has_tag?(card.tags, "healthy") && !has_tag?(card.tags, "unknown")
      severity = rand(2..19) * 5
    end

    PlayerCard.create!(player: player, card: card, severity: severity, revealed: false)
    player.reload
  end
end
