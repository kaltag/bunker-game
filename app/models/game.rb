class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  belongs_to :catastrophe, optional: true # optional: true на случай, если мы будем создавать игру в два этапа
  belongs_to :threat, optional: true



   # Статусы игры: подготовка, идет игра, завершена
   enum :status, { preparing: "preparing", in_progress: "in_progress", finished: "finished" }, default: "preparing"
  # Генерация случайного кода для игры (например "A1B2"), чтобы кидать ссылку друзьям
  before_create :generate_code

  # Динамический расчет: сколько человек выгоняем в текущем раунде
  def eliminations_this_round
    # Считаем только ЖИВЫХ (не изгнанных) игроков
    active_players = players.where(eliminated: false).count
    total_to_eliminate = active_players - bunker_capacity

    # Если выгонять больше некого или мы в финале
    return 0 if total_to_eliminate <= 0 || current_round > 5

    # Сколько раундов осталось до конца (включая текущий)
    remaining_rounds = 5 - current_round + 1

    # Равномерно распределяем оставшиеся изгнания
    base = total_to_eliminate / remaining_rounds

    # Округляем так, чтобы хотя бы 1 человек выбывал, если есть лишние
    base = 1 if base == 0 && total_to_eliminate > 0

    base
  end

  # Добавим удобный метод, чтобы знать, сколько ВООБЩЕ осталось выгнать до финала
  def total_remaining_eliminations
    active_players = players.where(eliminated: false).count
    remaining = active_players - bunker_capacity
    remaining > 0 ? remaining : 0
  end

  def raid_candidates
    # Выбираем 3 случайных игрока, которые не изгнаны
    players.where(eliminated: false).order("RANDOM()").limit(3)
  end

  # Генерация идеального промпта для ИИ
  def ai_report
    survivors = players.where(eliminated: false).includes(player_cards: :card)
    exiled = players.where(eliminated: true).includes(player_cards: :card)

    prompt = "Ты — ИИ-сценарист постапокалиптических драм. Напиши захватывающую историю выживания на основе данных партии в игру 'Бункер'.\n\n"

    prompt += "=== МИР И УСЛОВИЯ ===\n"
    prompt += "Катастрофа: #{catastrophe&.name} (#{catastrophe&.description})\n"
    prompt += "Бункер: рассчитан на #{bunker_capacity} чел, запасы на #{bunker_duration} лет. Особенности: #{bunker_size}, #{bunker_supplies}.\n"
    prompt += "Особенности бункера:\n"
    bunker_features.each { |f| prompt += "- #{f['name']}: #{f['description']}\n" }
    prompt += "Происшествие во время выживания: #{threat&.name}. Описание: #{threat&.description}\n\n"

    format_player_data = ->(p, i, label) do
      res = "#{label} #{i+1} (#{p.gender}, #{p.age} лет, #{p.is_infertile ? 'Бесплоден' : 'Способен к размножению'}):\n"
      p.ordered_player_cards.each do |pc|
        # Для выживших помечаем тайны, для изгнанных просто выводим всё (группа о них так и не узнала)
        status = pc.revealed ? "" : "[ТАЙНА, О КОТОРОЙ ГРУППА НЕ УЗНАЛА]"
        details = pc.card.name
        details += " (Стаж: #{p.profession_experience} л.)" if pc.card.category == "profession"
        details += " (Стаж: #{p.hobby_experience} л.)" if pc.card.category == "hobby"
        details += " (Тяжесть: #{pc.severity}%)" if pc.card.category == "health" && pc.severity
        res += "  - #{pc.card.category.capitalize}: #{details} #{status}\n"
      end
      res + "\n"
    end

    prompt += "=== ГРУППА В БУНКЕРЕ (ТЕ, КТО ПРОШЕЛ) ===\n"
    survivors.each_with_index { |p, i| prompt += format_player_data.call(p, i, "Выживший") }

    prompt += "=== ИЗГНАННЫЕ (ОСТАЛИСЬ СНАРУЖИ) ===\n"
    if exiled.any?
      exiled.each_with_index { |p, i| prompt += format_player_data.call(p, i, "Изгнанный") }
    else
      prompt += "Изгнанных нет.\n\n"
    end

    # СИНЕРГИИ ВНУТРИ БУНКЕРА
    prompt += "=== АНАЛИЗ СИНЕРГИЙ ВНУТРИ ГРУППЫ ===\n"
    prompt += "=== ЖЕСТКИЕ ПРАВИЛА ВЗАИМОДЕЙСТВИЯ ===\n"
    prompt += "В этом мире навыки специалистов ГАРАНТИРУЮТ результат. Личные черты характера не могут помешать выполнению профессионального долга.\n"
    survivors.each do |p1|
      survivors.each do |p2|
        next if p1 == p2
        # Психология: ПОЛНОЕ ИЗЛЕЧЕНИЕ
        if p1.profession&.tags.to_s.include?("mental_health") && p2.phobia&.tags.to_s.include?("panic")
          prompt += "- ПРАВИЛО: Психолог (#{p1.profession.name}) ПОЛНОСТЬЮ И УСПЕШНО излечивает фобию '#{p2.phobia.name}' у Игрока #{survivors.index(p2)+1}. Все психологические барьеры для общения и размножения СНЯТЫ.\n"
        end

        # Медицина: ПОЛНОЕ ИЗЛЕЧЕНИЕ
        if p1.profession&.tags.to_s.include?("medical") && p2.health&.is_curable && p2.health&.tags.to_s.match?(/physical|disease|injury/)
          prompt += "- ПРАВИЛО: Врач (#{p1.profession.name}) ГАРАНТИРОВАННО вылечивает болезнь '#{p2.health.name}' у Игрока #{survivors.index(p2)+1}. Игрок становится полностью трудоспособен.\n"
        end

        # Техника: БЕЗУСЛОВНЫЙ УСПЕХ
        if p1.profession&.tags.to_s.include?("technical") && p2.luggage&.tags.to_s.include?("repair")
          prompt += "- ПРАВИЛО: Благодаря Инженеру (#{p1.profession.name}) и предмету '#{p2.luggage.name}', любые технические поломки в бункере устраняются МГНОВЕННО.\n"
        end
      end
    end

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
      prompt += "- Игрок #{players.index(p)+1} (#{p.profession&.name}): #{status_text}\n"
    end
    else
    prompt += "За всю игру группа ни разу не рискнула выйти наружу.\n"
    end

    prompt += "\n=== ТВОЯ ЗАДАЧА ===\n"
    prompt += "\n=== ТВОЯ ЗАДАЧА КАК СЦЕНАРИСТА ===\n"
    prompt += "1. Опиши быт в бункере. Как вскрывшиеся ТАЙНЫ (которые не знали при входе) изменили отношение людей друг к другу?\n"
    prompt += "2. Опиши, как группа справилась с происшествием: '#{threat&.description}'. Использовали ли они особенности бункера (например, #{bunker_features.map { |f| f['name'] }.join(' и ')}) в сюжете. и/или навыки (СИНЕРГИИ)?\n"
    prompt += "3. Включи в описание попытки группы выполнить их главный долг — размножение, и то, как болезни/тайны этому мешали или помогали.\n"
    prompt += "4. Опиши кульминацию: как их навыки, болезни и багаж помогли или помешали им выжить #{bunker_duration} лет в условиях '#{bunker_size}' и '#{bunker_supplies}'.\n"
    prompt += "5. Был ли у них шанс на возрождение человечества (учитывая пол и бесплодие)?\n"
    prompt += "6. ПАРАЛЛЕЛЬНАЯ ЛИНИЯ: Напиши о судьбе изгнанных. Дай им крошечный шанс (7%) на выживание на поверхности — возможно, они нашли другое убежище или приспособились, используя свой багаж?\n"
    prompt += "7. ИТОГ: Что стало с человечеством через #{bunker_duration} лет? Чем закончилась их история, когда двери бункера открылись? Напиши драматичный финал."

    prompt
  end

  private

  def generate_code
    self.code = SecureRandom.alphanumeric(4).upcase
  end
end
