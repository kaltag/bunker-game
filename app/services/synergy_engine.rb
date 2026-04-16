# app/services/synergy_engine.rb
#
# Data-driven движок синергий. Все синергии описаны как данные в REGISTRY.
# GameGenerator вызывает SynergyEngine.apply(players, cards_pool, catastrophe_tags)
# и получает список сработавших синергий.
#
# ВАЖНО: синергии используют ТЕГИ для поиска карт, а не конкретные имена.
# Это гарантирует разнообразие — одна синергия даёт разные карты каждую партию.
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
  # Максимум синергий за партию — 40% от числа игроков (2-3 для 6, 3 для 8)
  MAX_SYNERGY_RATIO = 0.4

  REGISTRY = [
    # ================================================================
    # ПАРНЫЕ ПРОФЕССИИ (два игрока усиливают друг друга)
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
      partner: { profession_tag: "security" },
      give_to: :trigger, give_category: "luggage",
      give_tags: %w[weapon security]
    },
    {
      name: "Лаборатория", type: :pair,
      trigger: { profession_tag: "science" },
      partner: { profession_tag: "technical" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[technical software science]
    },
    {
      name: "Бригада", type: :pair,
      trigger: { profession_tag: "technical" },
      partner: { profession_tag: "building" },
      give_to: :partner, give_category: "luggage",
      give_tags: %w[technical building repair]
    },
    {
      name: "Дипломатия", type: :pair,
      trigger: { profession_tag: "mental_health" },
      partner: { profession_tag: "social" },
      give_to: :partner, give_category: "hobby",
      give_tags: %w[social mental_health mental]
    },
    {
      name: "Егеря", type: :pair,
      trigger: { profession_tag: "hunting" },
      partner: { profession_tag: "nature" },
      give_to: :trigger, give_category: "hobby",
      give_tags: %w[survival hunting nature]
    },

    # ================================================================
    # ПРОФЕССИЯ → КАРТА ДРУГОМУ (конфликты и связи)
    # Все используют ТЕГИ — каждый раз разная карта
    # ================================================================
    {
      name: "Врач и пациент", type: :inject,
      trigger: { profession_tag: "medical" },
      give_category: "health", give_filter: :curable_disease
    },
    {
      name: "Психолог и фобия", type: :inject,
      trigger: { profession_tag: "mental_health" },
      give_category: "phobia", give_tags: %w[panic]
    },
    {
      name: "Детектив и подозреваемый", type: :inject,
      trigger: { profession_tag: "security" },
      give_category: "fact", give_tags: %w[criminal danger]
    },
    {
      name: "Алкогольная зависимость", type: :inject,
      trigger: { profession_tag: "alcohol" },
      give_category: "health", give_tags: %w[addiction]
    },
    {
      name: "Химик и побочный эффект", type: :inject,
      trigger: { any_profession_tag: %w[chemical science] },
      give_category: "health", give_tags: %w[disease mental]
    },
    {
      name: "Священник и грешник", type: :inject,
      trigger: { profession_tag: "social" },
      give_category: "fact", give_tags: %w[cult strange mental]
    },

    # ================================================================
    # ПРОФЕССИЯ → ПРЕДМЕТ (себе или партнёру)
    # ================================================================
    {
      name: "Фермер + запасы", type: :inject,
      trigger: { profession_tag: "agriculture" },
      give_category: "luggage", give_tags: %w[farming food]
    },
    {
      name: "Инженер + инструменты", type: :inject,
      trigger: { profession_tag: "technical" },
      give_category: "luggage", give_tags: %w[repair technical]
    },
    {
      name: "Повар + провизия", type: :inject,
      trigger: { profession_tag: "food" },
      give_category: "luggage", give_tags: %w[food]
    },
    {
      name: "Военный + снаряжение", type: :inject,
      trigger: { profession_tag: "security" },
      give_to_self_chance: 50,
      give_category: "luggage", give_tags: %w[weapon security survival]
    },
    {
      name: "Хакер + техника", type: :inject,
      trigger: { profession_tag: "software" },
      give_to_self_chance: 50,
      give_category: "luggage", give_tags: %w[software technical]
    },
    {
      name: "Творческий и страдалец", type: :inject,
      trigger: { any_profession_tag: %w[art social] },
      give_category: "health", give_tags: %w[mental]
    },

    # ================================================================
    # САМОИРОНИЯ (конфликтующая карта себе)
    # Все через теги — каждый раз случайная карта-конфликт
    # ================================================================
    {
      name: "Профессионал с изъяном", type: :self_irony,
      trigger: { profession_tag: "surgery" },
      give_category: "health", give_tags: %w[disability physical]
    },
    {
      name: "Технофоб-технарь", type: :self_irony,
      trigger: { profession_tag: "software" },
      give_category: "phobia", give_tags: %w[panic mental]
    },
    {
      name: "Клаустрофоб в бункере", type: :self_irony,
      trigger: :random_player,
      give_category: "phobia", give_tags: %w[panic]
    },
    {
      name: "Военный с травмой", type: :self_irony,
      trigger: { profession_tag: "security" },
      give_category: "health", give_tags: %w[mental disability]
    },

    # ================================================================
    # ХОББИ → ПРЕДМЕТ (хобби усиливается багажом)
    # ================================================================
    {
      name: "Выживальщик", type: :hobby_boost,
      trigger: { hobby_tag: "survival" },
      give_category: "luggage", give_tags: %w[weapon survival exploration]
    },
    {
      name: "Радист", type: :hobby_boost,
      trigger: { hobby_tag: "communication" },
      give_category: "luggage", give_tags: %w[communication technical]
    },
    {
      name: "Мастер на все руки", type: :hobby_boost,
      trigger: { hobby_tag: "crafting" },
      give_category: "luggage", give_tags: %w[technical building repair]
    },
    {
      name: "Травник", type: :hobby_boost,
      trigger: { hobby_tag: "nature" },
      give_category: "fact", give_tags: %w[nature survival]
    },

    # ================================================================
    # КАТАСТРОФА-СПЕЦИФИЧНЫЕ (через теги, не имена)
    # ================================================================
    {
      name: "Радиационное снаряжение", type: :catastrophe,
      catastrophe_tags: %w[radiation],
      give_category: "luggage", give_tags: %w[radiation science survival]
    },
    {
      name: "Химзащита", type: :catastrophe,
      catastrophe_tags: %w[chemical],
      give_category: "luggage", give_tags: %w[medical survival science]
    },
    {
      name: "Тематическая фобия", type: :catastrophe,
      catastrophe_tags: %w[water mental strange],
      give_category: "phobia", give_tags: %w[panic]
    },
    {
      name: "Полезное хобби", type: :catastrophe,
      catastrophe_tags: %w[food survival nature],
      give_category: "hobby", give_tags: %w[food survival nature agriculture]
    },

    # ================================================================
    # ПЕРЕКРЁСТНЫЕ ФАКТЫ (двум игрокам связанные, но РАЗНЫЕ карты)
    # ================================================================
    {
      name: "Два секрета", type: :cross_fact,
      give_both_category: "mixed",
      player_a_category: "fact", player_a_tags: %w[criminal danger],
      player_b_category: "fact", player_b_tags: %w[info social strange]
    },
    {
      name: "Странная связь", type: :cross_fact,
      give_both_category: "mixed",
      player_a_category: "fact", player_a_tags: %w[strange mental],
      player_b_category: "health", player_b_tags: %w[mental]
    },
  ].freeze

  def initialize(cards_pool, catastrophe_tags = [])
    @cards_pool = cards_pool
    @catastrophe_tags = catastrophe_tags
    @applied = []
    @used_card_ids = Set.new
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

    partner_player = find_by_condition(players, syn[:partner], exclude: trigger_player)
    return false unless partner_player

    receiver = syn[:give_to] == :trigger ? trigger_player : partner_player
    return false if player_has_category?(receiver, syn[:give_category])

    card = find_card(syn)
    return false unless card

    give_card!(receiver, card)
  end

  def apply_inject(syn, players)
    trigger_player = find_by_condition(players, syn[:trigger])
    return false unless trigger_player

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
  end

  def apply_catastrophe(syn, players)
    return false unless (syn[:catastrophe_tags] & @catastrophe_tags).any?

    receiver = available_for(players, syn[:give_category]).sample
    return false unless receiver

    card = find_card(syn)
    return false unless card

    give_card!(receiver, card)
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
  end

  def apply_cross_fact(syn, players)
    cat_a = syn[:player_a_category] || syn[:give_both_category]
    cat_b = syn[:player_b_category] || syn[:give_both_category]

    available_a = available_for(players, cat_a)
    return false if available_a.count < 2

    player_a = available_a.sample
    available_b = available_for(players, cat_b, exclude: player_a)
    player_b = available_b.sample
    return false unless player_a && player_b

    card_a = find_card_for_cross(syn, :a)
    card_b = find_card_for_cross(syn, :b)
    return false unless card_a && card_b

    # Гарантируем разные карты
    if card_a.id == card_b.id
      pool = available_pool(cat_b)
      card_b = pool.reject { |c| c.id == card_a.id }.sample
      return false unless card_b
    end

    result_a = give_card!(player_a, card_a)
    result_b = give_card!(player_b, card_b)
    result_a && result_b
  end

  # ================================================================
  # ПОИСК КАРТ (всегда через available_pool — без дублей)
  # ================================================================

  def find_card(syn)
    pool = available_pool(syn[:give_category])

    if syn[:give_filter] == :curable_disease
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
    pool = available_pool(cat)

    tags = syn[:"player_#{side}_tags"]

    if tags
      matching = pool.select { |c| (parse_tags(c.tags) & tags).any? }
      matching.any? ? matching.sample : nil
    else
      pool.sample
    end
  end

  # ================================================================
  # УТИЛИТЫ
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

  def player_has_category?(player, category)
    player.cards.any? { |c| c.category == category }
  end

  # Пул карт без уже выданных
  def available_pool(category)
    pool = @cards_pool[category] || []
    pool.reject { |c| @used_card_ids.include?(c.id) }
  end

  def has_tag?(tags_string, tag)
    parse_tags(tags_string).include?(tag)
  end

  def parse_tags(tags_string)
    tags_string.to_s.split(/,\s*/).map(&:strip).reject(&:empty?)
  end

  def give_card!(player, card)
    return false unless card
    return false if @used_card_ids.include?(card.id)

    severity = nil
    if card.category == "health" && !has_tag?(card.tags, "healthy") && !has_tag?(card.tags, "unknown")
      severity = rand(2..19) * 5
    end

    PlayerCard.create!(player: player, card: card, severity: severity, revealed: false)
    @used_card_ids.add(card.id)
    player.reload
    true
  end
end
