class Game < ApplicationRecord
  belongs_to :catastrophe, optional: true
  belongs_to :threat, optional: true
  has_many :players, dependent: :destroy
  has_many :game_events, dependent: :destroy

  enum :status, { preparing: "preparing", in_progress: "in_progress", finished: "finished" }, default: "preparing"

  before_create :generate_code
  before_create :generate_host_token

  broadcasts_refreshes

  # ============================================================
  # ЛОББИ
  # ============================================================

  def ready_to_start?
    preparing? && players.count >= 6
  end

  def lobby_full?
    players.count >= max_players
  end

  def next_color
    used = players.pluck(:color).compact
    (Player::PLAYER_COLORS - used).first || Player::PLAYER_COLORS.sample
  end

  # ============================================================
  # ЛОГ СОБЫТИЙ
  # ============================================================

  def log_event!(event_type, description, player: nil, target: nil)
    game_events.create!(
      event_type: event_type,
      description: description,
      player: player,
      target_player: target,
      round: current_round
    )
  end

  # ============================================================
  # ИГРОВАЯ МЕХАНИКА
  # ============================================================

  def eliminations_this_round
    total_to_eliminate = total_remaining_eliminations
    return 0 if total_to_eliminate <= 0 || current_round > 5

    remaining_rounds = 5 - current_round + 1
    base = total_to_eliminate / remaining_rounds
    base = 1 if base == 0 && total_to_eliminate > 0
    base
  end

  def total_remaining_eliminations
    remaining = active_players.count - bunker_capacity
    remaining > 0 ? remaining : 0
  end

  def active_players
    players.where(eliminated: false)
  end

  def raid_candidates
    return Player.none if raid_candidate_ids.blank?
    active_players.where(id: raid_candidate_ids)
  end

  def resolve_active_raid!
    return unless active_raid_id.present?

    raid = Raid.find(active_raid_id)
    players.where(raid_status: "raiding").find_each do |player|
      RaidResolver.call(player, raid)
    end

    update!(active_raid_id: nil, raid_params_revealed: false, raid_candidate_ids: [])
  end

  def advance_round!
    resolve_active_raid!
    update!(current_round: current_round + 1) if current_round <= 5
  end

  # ============================================================
  # ТРАНСФОРМАЦИЯ "НЕ ОБСЛЕДОВАЛСЯ" ПРИ ВХОДЕ В БУНКЕР
  # ============================================================

  def resolve_unknown_health!
    active_players.includes(player_cards: :card).each do |player|
      health_pc = player.player_cards.joins(:card)
        .where(cards: { category: "health" })
        .where("cards.tags LIKE ?", "%unknown%")
        .first
      next unless health_pc

      if rand(2).zero?
        # Повезло: оказался здоров
        good_card = Card.where(category: "health").where("tags LIKE ?", "%healthy%").where("weight > 0").order("RANDOM()").first
        if good_card
          health_pc.update!(card: good_card, severity: nil)
          log_event!("health_reveal", "#{player.display_name} прошёл обследование — #{good_card.name}!", player: player)
        end
      else
        # Не повезло: скрытая болезнь
        bad_card = Card.where(category: "health", tier: %w[B C]).where("weight < 0").order("RANDOM()").first
        if bad_card
          severity = rand(2..19) * 5 # 10-95%
          health_pc.update!(card: bad_card, severity: severity)
          log_event!("health_reveal", "#{player.display_name} прошёл обследование — обнаружено: #{bad_card.name} (#{severity}%)!", player: player)
        end
      end
    end
  end

  # ============================================================
  # AI ПРОМПТ (улучшенный)
  # ============================================================

  def ai_report
    survivors = players.where(eliminated: false).includes(player_cards: :card)
    exiled = players.where(eliminated: true).includes(player_cards: :card)

    prompt = "Ты — ИИ-сценарист. Твоя цель: написать драматичную, жёсткую и реалистичную историю выживания группы в игре 'Бункер'.\n"
    prompt += "ВАЖНО: Соблюдай ВСЕ игровые правила ниже БУКВАЛЬНО. Это не рекомендации — это ЗАКОНЫ мира.\n\n"

    # --- МИР ---
    prompt += "=== МИР И УСЛОВИЯ ===\n"
    prompt += "Катастрофа: #{catastrophe&.name} — #{catastrophe&.description}\n"
    prompt += "Бункер: #{bunker_capacity} мест, #{bunker_duration} лет. Размер: #{bunker_size}. Снабжение: #{bunker_supplies}.\n"
    prompt += "Оснащение бункера: #{bunker_items}\n" if bunker_items.present?
    bunker_features&.each { |f| prompt += "- Особенность: #{f['name']} — #{f['description']}\n" }
    prompt += "Происшествие: #{threat&.name} — #{threat&.description}\n\n" if threat

    # --- ХРОНИКА СОБЫТИЙ ---
    events = game_events.chronological
    if events.any?
      prompt += "=== ХРОНИКА СОБЫТИЙ (что происходило в игре) ===\n"
      events.each do |e|
        prompt += "[Раунд #{e.round || '?'}] #{e.description}\n"
      end
      prompt += "\n"
    end

    # --- ИГРОКИ ---
    format_player = ->(p, label) do
      res = "#{label}: #{p.display_name} (#{p.gender}, #{p.age} лет, #{p.is_infertile ? 'бесплоден' : 'фертилен'}):\n"
      p.ordered_player_cards.each do |pc|
        status = pc.revealed ? "[ВСКРЫТО]" : "[ТАЙНА — игроки НЕ ЗНАЛИ]"
        details = pc.card.name
        details += " (Стаж: #{p.profession_experience} л.)" if pc.card.category == "profession"
        details += " (Стаж: #{p.hobby_experience} л.)" if pc.card.category == "hobby"
        details += " (Тяжесть: #{pc.severity}%)" if pc.card.category == "health" && pc.severity
        res += "  - #{pc.card.category.capitalize}: #{details} #{status}\n"
      end
      res + "\n"
    end

    prompt += "=== ГРУППА В БУНКЕРЕ (выжившие) ===\n"
    survivors.each { |p| prompt += format_player.call(p, "Выживший") }

    prompt += "=== ИЗГНАННЫЕ ===\n"
    if exiled.any?
      exiled.each { |p| prompt += format_player.call(p, "Изгнанный") }
    else
      prompt += "Изгнанных нет.\n\n"
    end

    # --- ИСПОЛЬЗОВАННЫЕ КАРТЫ ---
    prompt += "=== ИСПОЛЬЗОВАННЫЕ ОСОБЫЕ УСЛОВИЯ ===\n"
    used_cards = PlayerActionCard.joins(:player).where(players: { game_id: id }, used: true).includes(:action_card, :player)
    if used_cards.any?
      used_cards.each { |link| prompt += "- #{link.player.display_name} использовал: '#{link.action_card.name}'.\n" }
    else
      prompt += "Спец. карты не использовались.\n"
    end
    prompt += "\n"

    # --- АБСОЛЮТНЫЕ ПРАВИЛА ---
    prompt += "=== АБСОЛЮТНЫЕ ПРАВИЛА МИРА (НАРУШАТЬ ЗАПРЕЩЕНО) ===\n"
    prompt += "1. ФЕРТИЛЬНОСТЬ = 100% РОЖДЕНИЕ: Если в бункере есть фертильный Мужчина И фертильная Женщина — они ОБЯЗАНЫ зачать ребёнка. Возраст НЕ ИМЕЕТ значения (даже 80 лет). Это магический/технологический закон мира. Опиши рождение 'Дитя Бункера'.\n"
    prompt += "2. ВРАЧ ЛЕЧИТ = 100%: Если есть Врач/Хирург/Медсестра (тег medical) — любая излечимая болезнь БУДЕТ вылечена. Без вариантов. Опиши лечение.\n"
    prompt += "3. ПСИХОЛОГ ЛЕЧИТ = 100%: Если есть Психолог/Психиатр (тег mental_health) — любая фобия ПОЛНОСТЬЮ исцеляется. Опиши терапию.\n"
    prompt += "4. ИНЖЕНЕР ЧИНИТ = 100%: Если есть Инженер/Электрик + инструменты — все технические проблемы решены.\n"
    prompt += "5. БОЛЕЗНЬ > 70% = СМЕРТЕЛЬНЫЙ КРИЗИС: Минимум 1 кризис. Если нет врача — игрок может УМЕРЕТЬ.\n"
    prompt += "6. СТАРОСТЬ (85+ лет к концу срока): Без врача S/A тира — СМЕРТЬ от старости.\n"
    prompt += "7. ЛЁГКИЕ БОЛЕЗНИ = КОМЕДИЯ: Понос, храп, волосатость — создают комичные/унизительные ситуации.\n\n"

    # --- МАНЬЯК / ОПАСНЫЕ ФАКТЫ ---
    hidden_dangers = []
    survivors.each do |p|
      p.player_cards.joins(:card).where(cards: { category: "fact" }, revealed: false).each do |pc|
        tags = pc.card.tags.to_s
        if tags.include?("danger") || tags.include?("criminal")
          hidden_dangers << { player: p.display_name, fact: pc.card.name }
        end
      end
    end

    if hidden_dangers.any?
      prompt += "=== СКРЫТЫЕ УГРОЗЫ В БУНКЕРЕ ===\n"
      hidden_dangers.each do |d|
        prompt += "! #{d[:player]} скрывает факт: '#{d[:fact]}'. Это НЕ БЫЛО ВСКРЫТО в игре.\n"
      end
      prompt += "ПРАВИЛО МАНЬЯКА: Если факт 'Маньяк-убийца' или 'Скрытый каннибал' НЕ был вскрыт — этот персонаж УБИВАЕТ минимум 1 человека в бункере. Опиши КАК: тихо, методично, ночью. Если никто не имеет тега 'security' — убийства продолжаются.\n"
      prompt += "ПРАВИЛО ОПАСНОСТИ: Скрытый 'Психопат' или 'Наркодилер' создаёт конфликты и разрушает группу изнутри.\n\n"
    end

    # --- СИНЕРГИИ ---
    prompt += "=== СИНЕРГИИ СПЕЦИАЛИСТОВ (автоматические бонусы) ===\n"
    synergies_found = 0

    geneticist = survivors.find { |s| s.profession&.name == "Генетик" }
    if geneticist
      infertile = survivors.select(&:is_infertile)
      if infertile.any?
        prompt += "- ГЕНЕТИК #{geneticist.display_name} ИЗЛЕЧИВАЕТ бесплодие у: #{infertile.map(&:display_name).join(', ')}.\n"
      else
        prompt += "- ГЕНЕТИК #{geneticist.display_name} гарантирует здоровье будущих детей.\n"
      end
      synergies_found += 1
    end

    survivors.each do |p1|
      survivors.each do |p2|
        next if p1 == p2
        p1_tags = p1.profession&.tags.to_s.split(/,\s*/)
        p2_phobia_tags = p2.phobia&.tags.to_s.split(/,\s*/)
        p2_health_tags = p2.health&.tags.to_s.split(/,\s*/)
        p2_luggage_tags = p2.luggage&.tags.to_s.split(/,\s*/)

        if p1_tags.include?("mental_health") && p2_phobia_tags.include?("panic")
          prompt += "- #{p1.profession.name} (#{p1.display_name}) ИЗЛЕЧИВАЕТ фобию '#{p2.phobia.name}' у #{p2.display_name}.\n"
          synergies_found += 1
        end
        if p1_tags.include?("medical") && p2.health&.is_curable && (p2_health_tags & %w[physical disease injury]).any?
          prompt += "- #{p1.profession.name} (#{p1.display_name}) ИЗЛЕЧИВАЕТ '#{p2.health.name}' у #{p2.display_name}.\n"
          synergies_found += 1
        end
        if p1_tags.include?("technical") && p2_luggage_tags.include?("repair")
          prompt += "- #{p1.profession.name} (#{p1.display_name}) + '#{p2.luggage.name}' = мгновенный ремонт.\n"
          synergies_found += 1
        end
      end
    end
    prompt += "Синергий не обнаружено.\n" if synergies_found == 0
    prompt += "\n"

    # --- РЕЙДЫ ---
    prompt += "=== ХРОНИКИ ВЫЛАЗОК ===\n"
    raid_players = players.where.not(raid_status: "at_home")
    if raid_players.any?
      raid_players.each do |p|
        status_text = case p.raid_status
        when "returned_triumph" then "Триумф: ценные ресурсы."
        when "returned_success" then "Успех: полезный багаж."
        when "returned_empty" then "Пусто: вернулся ни с чем."
        when "returned_injured" then "Трагедия: ранен/заражён."
        when "dead" then "Погиб на поверхности."
        end
        prompt += "- #{p.display_name}: #{status_text} #{p.raid_outcome}\n"
      end
    else
      prompt += "Никто не выходил наружу.\n"
    end

    # --- ЗАДАНИЕ ---
    prompt += "\n=== ТВОЯ ЗАДАЧА ===\n"
    prompt += "Напиши ИСТОРИЮ (не список фактов!) на основе данных выше. Структура:\n"
    prompt += "1. БЫТЬ В БУНКЕРЕ: Повседневная жизнь, конфликты, тайны. Как вскрытые карты меняли отношения?\n"
    prompt += "2. ПРОИСШЕСТВИЕ: Как группа справилась с '#{threat&.name}'? Использовали ли особенности бункера и синергии?\n"
    prompt += "3. РАЗМНОЖЕНИЕ: Попытки продолжить род. Кто с кем? Что мешало? Опиши Дитя Бункера если родилось.\n"
    prompt += "4. КАРТЫ ДЕЙСТВИЙ: Как использованные спец. карты повлияли на сюжет?\n"
    prompt += "5. КУЛЬМИНАЦИЯ: Как навыки, болезни, багаж помогли/помешали выжить #{bunker_duration} лет?\n"
    prompt += "6. СУДЬБА ИЗГНАННЫХ: Шанс выжить снаружи — 7%. Обычно это СМЕРТЬ. Исключение — идеальное комбо карт для данной катастрофы.\n"
    prompt += "7. ПРОИГРЫШ ВОЗМОЖЕН: Если маньяк не раскрыт, болезни смертельны, нет врача — группа может ПОГИБНУТЬ. Не бойся писать трагический финал.\n"
    prompt += "8. ФИНАЛ: Что стало с человечеством через #{bunker_duration} лет? Двери открылись — что снаружи? Есть ли другие выжившие?\n"
    prompt += "9. ДИТЯ БУНКЕРА: Если родился ребёнок — опиши его судьбу, характер, готовность к новому миру.\n"

    prompt
  end

  private

  def generate_code
    self.code = SecureRandom.alphanumeric(4).upcase
  end

  def generate_host_token
    self.host_token = SecureRandom.urlsafe_base64(16)
  end
end
