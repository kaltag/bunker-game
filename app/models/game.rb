class Game < ApplicationRecord
  belongs_to :catastrophe
  belongs_to :threat, optional: true
  has_many :players, dependent: :destroy

  # Статусы игры: подготовка, идет игра, завершена
  enum :status, { preparing: "preparing", in_progress: "in_progress", finished: "finished" }, default: "preparing"
  # Генерация случайного кода для игры (например "A1B2"), чтобы кидать ссылку друзьям
  before_create :generate_code

  broadcasts_refreshes

  # Динамический расчет: сколько человек выгоняем в текущем раунде
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
    active_players.order("RANDOM()").limit(3)
  end

  # Завершает активный рейд: разрешает исходы для всех рейдеров
  def resolve_active_raid!
    return unless active_raid_id.present?

    raid = Raid.find(active_raid_id)
    players.where(raid_status: "raiding").find_each do |player|
      RaidResolver.call(player, raid)
    end

    update!(active_raid_id: nil, raid_params_revealed: false)
  end

  # Переход к следующему раунду с разрешением рейда
  def advance_round!
    resolve_active_raid!
    update!(current_round: current_round + 1) if current_round <= 5
  end

  # Генерация идеального промпта для ИИ
  def ai_report
    survivors = players.where(eliminated: false).includes(player_cards: :card)
    exiled = players.where(eliminated: true).includes(player_cards: :card)

    prompt = "Ты — ИИ-сценарист. Твоя цель: написать драматичную историю выживания группы в игре 'Бункер', учитывая ЖЕСТКУЮ логику навыков и болезней.\n\n"

    prompt += "=== МИР И УСЛОВИЯ ===\n"
    prompt += "Катастрофа: #{catastrophe&.name} (#{catastrophe&.description})\n"
    prompt += "Бункер: #{bunker_capacity} чел, #{bunker_duration} лет. #{bunker_size}, #{bunker_supplies}.\n"
    prompt += "Лут: #{bunker_items}\n"
    bunker_features.each { |f| prompt += "- #{f['name']}: #{f['description']}\n" }
    prompt += "Происшествие: #{threat&.name} (#{threat&.description})\n\n"

    format_player_data = ->(p, _i, label) do
      res = "#{label}: #{p.display_name} (#{p.gender}, #{p.age} лет, #{p.is_infertile ? 'Бесплоден' : 'Способен к размножению'}):\n"
      p.ordered_player_cards.each do |pc|
        status = pc.revealed ? "" : "[ТАЙНА]"
        details = pc.card.name
        details += " (Стаж: #{p.profession_experience} л.)" if pc.card.category == "profession"
        details += " (Стаж: #{p.hobby_experience} л.)" if pc.card.category == "hobby"
        details += " (Тяжесть: #{pc.severity}%)" if pc.card.category == "health" && pc.severity
        res += "  - #{pc.card.category.capitalize}: #{details} #{status}\n"
      end
      res + "\n"
    end

    prompt += "=== ИСПОЛЬЗОВАННЫЕ ОСОБЫЕ УСЛОВИЯ ===\n"
    used_cards = PlayerActionCard.joins(:player).where(players: { game_id: id }, used: true)

    if used_cards.any?
      used_cards.includes(:action_card, :player).each do |link|
        prompt += "- #{link.player.display_name} разыграл карту: '#{link.action_card.name}'.\n"
      end
    else
      prompt += "Спец. карты не использовались.\n"
    end

    prompt += "=== ГРУППА В БУНКЕРЕ ===\n"
    survivors.each_with_index { |p, i| prompt += format_player_data.call(p, i, "Выживший") }

    prompt += "=== ИЗГНАННЫЕ ===\n"
    if exiled.any?
      exiled.each_with_index { |p, i| prompt += format_player_data.call(p, i, "Изгнанный") }
    else
      prompt += "Изгнанных нет.\n\n"
    end

    prompt += "=== ПРАВИЛА МИРА (СОБЛЮДАТЬ ОБЯЗАТЕЛЬНО) ===\n"
    prompt += "1. ЗАКОН ТЕГА 'СПОСОБЕН К РАЗМНОЖЕНИЮ': Это магический/технологический статус. Если у Мужчины и Женщины стоит этот тег, они ОБЯЗАНЫ зачать и родить здорового ребенка в первые годы в бункере, НЕЗАВИСИМО ОТ ВОЗРАСТА (даже если женщине 80 лет). Игнорируй биологический климакс. Опиши рождение и воспитание 'Дитя Бункера' — это единственный шанс на выживание вида.\n"
    prompt += "2. ЗАКОН СМЕРТНОСТИ: Если в течение срока игрок достигает возраста 85+ лет, он должен столкнуться со смертельным кризисом от старости. Если в группе НЕТ Врача, Хирурга или Генетика (Tier S/A), этот игрок УМИРАЕТ к концу срока. Не позволяй 90-летним старикам бодро выходить из бункера без медицинской помощи высокого уровня.\n"
   prompt += "3. ВЕС БОЛЕЗНЕЙ: Если у игрока болезнь тяжестью > 70%, опиши МИНИМУМ ОДИН смертельно опасный кризис. Если болезнь лайтовая (понос), это должно создать комичную или унизительную ситуацию, мешающую выживанию.\n\n"
    # Синергии специалистов
    geneticist = survivors.find { |s| s.profession&.name == "Генетик" }
    infertile_survivors = survivors.select(&:is_infertile)

    if geneticist
      if infertile_survivors.any?
        prompt += "2. НАУЧНЫЙ ПРОРЫВ: Генетик (#{geneticist.display_name}) использует передовые технологии для ИЗЛЕЧЕНИЯ биологического бесплодия у следующих выживших: #{infertile_survivors.map(&:display_name).join(', ')}. Это ПРИОРИТЕТНАЯ задача. Опиши, как благодаря науке те, кто считался бесплодным, получили шанс стать родителями.\n"
      else
        prompt += "2. НАУЧНЫЙ ПРОРЫВ: Генетик (#{geneticist.display_name}) гарантирует идеальное здоровье будущих детей, исправляя любые генетические дефекты у фертильных членов группы.\n"
      end
    end

    survivors.each do |p1|
      survivors.each do |p2|
        next if p1 == p2
        # Психология: ПОЛНОЕ ИЗЛЕЧЕНИЕ
        if p1.profession&.tags.to_s.include?("mental_health") && p2.phobia&.tags.to_s.include?("panic")
          prompt += "- ПРАВИЛО: Психолог (#{p1.profession.name}) ПОЛНОСТЬЮ излечивает фобию '#{p2.phobia.name}' у #{p2.display_name}.\n"
        end

        # Медицина: ПОЛНОЕ ИЗЛЕЧЕНИЕ
        if p1.profession&.tags.to_s.include?("medical") && p2.health&.is_curable && p2.health&.tags.to_s.match?(/physical|disease|injury/)
          prompt += "- ПРАВИЛО: Врач (#{p1.profession.name}) ГАРАНТИРОВАННО вылечивает болезнь '#{p2.health.name}' у #{p2.display_name}. Игрок становится полностью трудоспособен.\n"
        end

        # Техника: БЕЗУСЛОВНЫЙ УСПЕХ
        if p1.profession&.tags.to_s.include?("technical") && p2.luggage&.tags.to_s.include?("repair")
          prompt += "- ПРАВИЛО: Благодаря Инженеру (#{p1.profession.name}) и предмету '#{p2.luggage.name}', любые технические поломки в бункере устраняются МГНОВЕННО.\n"
        end
      end
    end
    # === ХРОНИКИ ВНЕШНИХ ВЫЛАЗОК (РЕЙДЫ) ===
    prompt += "=== ХРОНИКИ ВНЕШНИХ ВЫЛАЗОК (РЕЙДЫ) ===\n"
    raid_events = players.where.not(raid_status: "at_home")

    if raid_events.any?
      raid_events.each do |p|
        status_text = case p.raid_status
        when "returned_triumph" then "Триумфальное возвращение: нашел ценные ресурсы и новые инструкции."
        when "returned_success" then "Успех: вернулся с полезным багажом."
        when "returned_empty" then "Неудача: вернулся живым, но с пустыми руками."
        when "returned_injured" then "Трагедия: вернулся с тяжелыми ранениями/болезнью."
        when "dead" then "Героическая гибель: не вернулся из вылазки."
        end
        prompt += "- #{p.display_name} (#{p.profession&.name || 'Профессия скрыта'}): #{status_text}\n"
      end
    else
      prompt += "За всю игру группа ни разу не рискнула выйти наружу.\n"
    end

    prompt += "\n=== ТВОЯ ЗАДАЧА ===\n"
    prompt += "1. Опиши быт в бункере. Как вскрывшиеся ТАЙНЫ (которые не знали при входе) изменили отношение людей друг к другу?\n"
    prompt += "2. Опиши, как группа справилась с происшествием: '#{threat&.description}'. Использовали ли они особенности бункера (например, #{bunker_features.map { |f| f['name'] }.join(' и ')}) в сюжете. и/или навыки (СИНЕРГИИ)?\n"
    prompt += "3. Включи в описание попытки группы выполнить их главный долг — размножение, и то, как болезни/тайны этому мешали или помогали.\n"
    prompt += "4. Учти в сюжете использованные карты действий (особенно если они изменили состав бункера или ресурсы).\n"
    prompt += "5. Опиши кульминацию: как их навыки, болезни и багаж помогли или помешали им выжить #{bunker_duration} лет в условиях '#{bunker_size}' и '#{bunker_supplies}'.\n"
    prompt += "6. Был ли у них шанс на возрождение человечества (учитывая пол и бесплодие)?\n"
    prompt += "7.СУДЬБА ИЗГНАННЫХ (ЖЕСТКО): Шанс выжить снаружи — ВСЕГО 7%. Это почти НОЛЬ. В 9 случаях из 10 изгнанные должны ПОГИБНУТЬ мучительной смертью в первые же месяцы. Пиши о выживании изгнанного только если его набор карт (профессия + багаж) — это абсолютное комбо для данной катастрофы. В остальном — описывай их гибель.\n"
    prompt += "8. ИТОГ: Что стало с человечеством через #{bunker_duration} лет? Чем закончилась их история, когда двери бункера открылись? Напиши драматичный финал. Не ограничивайся группой. Напиши, что случилось с цивилизацией во всем мире. Есть ли другие очаги жизни?"
    prompt += "9. СУДЬБА ДЕТЕЙ: Опиши судьбу ребенка, родившегося в бункере. Как он выглядит, во что верит и готов ли он выйти в мир, который никогда не видел?\n"

    prompt
  end

  private

  def generate_code
    self.code = SecureRandom.alphanumeric(4).upcase
  end
end
