class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  belongs_to :catastrophe, optional: true # optional: true на случай, если мы будем создавать игру в два этапа


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

# Генерация идеального промпта для ИИ
def ai_report
  survivors = players.where(eliminated: false).includes(player_cards: :card)
  exiled = players.where(eliminated: true).includes(player_cards: :card)

  prompt = "Ты — ИИ-сценарист постапокалиптических драм. Напиши захватывающую историю выживания на основе данных партии в игру 'Бункер'.\n\n"

  prompt += "=== МИР И УСЛОВИЯ ===\n"
  prompt += "Катастрофа: #{catastrophe&.name} (#{catastrophe&.description})\n"
  prompt += "Бункер: рассчитан на #{bunker_capacity} чел, запасы на #{bunker_duration} лет. Особенности: #{bunker_size}, #{bunker_supplies}.\n\n"

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
  survivors.each do |p1|
    survivors.each do |p2|
      next if p1 == p2
     if p1.profession&.tags&.include?("medical") && p2.health&.is_curable && p2.health&.tags&.match?(/physical|disease|injury/)
        prompt += "- Медицина: #{p1.profession.name} может спасти жизнь Игроку с болезнью '#{p2.health.name}'.\n"
     end

      # Проверяем психологию (психолог + фобия)
      if p1.profession&.tags&.include?("mental_health") && p2.phobia&.tags&.include?("panic")
        prompt += "- Психология: Психолог может купировать фобию '#{p2.phobia.name}' у соседа.\n"
      end

      # Проверяем технику (инженер + багаж)
      if p1.profession&.tags&.include?("technical") && p2.luggage&.tags&.include?("repair")
        prompt += "- Инженерия: #{p1.profession.name} эффективно использует предмет '#{p2.luggage.name}'.\n"
      end
    end
  end

  prompt += "\n=== ТВОЯ ЗАДАЧА ===\n"
  prompt += "\n=== ТВОЯ ЗАДАЧА КАК СЦЕНАРИСТА ===\n"
  prompt += "1. Опиши быт в бункере. Как вскрывшиеся ТАЙНЫ (которые не знали при входе) изменили отношение людей друг к другу?\n"
  prompt += "2. Используй СИНЕРГИИ: опиши сцены спасения или совместной работы специалистов.\n"
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
