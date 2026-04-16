# app/services/raid_resolver.rb
class RaidResolver
  def self.call(player, raid)
    # 1. Собираем АБСОЛЮТНО ВСЕ теги игрока (и открытые, и скрытые)
    all_tags = player.cards.pluck(:tags).join(", ") + player.profession&.tags.to_s

    # 2. Рассчитываем модификатор навыков
    score = 0
    # Навыки которые помогают (+20 за каждый)
    raid.required_tags.split(", ").each { |t| score += 20 if all_tags.include?(t) }
    # Опасности которые мешают (-20 за каждый)
    raid.dangerous_tags.split(", ").each { |t| score -= 20 if all_tags.include?(t) }

    # 3. Учитываем возраст и состояние
    score -= 15 if player.age > 60 || player.age < 20
    score -= 20 if player.health&.tags.to_s.include?("disability")
    score += 10 if player.hobby&.tags.to_s.include?("survival")

    # 4. Базовый бросок кубика (1..100) + наш score
    # Средний шанс выжить будет около 60-70%, если игрок подходит под рейд
    final_roll = rand(1..100) + score

   case final_roll
   when 90..200 # ТРИУМФ
      reward = give_luggage(player, "S")
      give_action_card(player)
      message = "Героический успех! Нашел: #{reward} и новую карту условий."
      player.update!(raid_status: "returned_triumph", raid_outcome: message)

   when 60..89 # УСПЕХ
      reward = give_luggage(player, "A")
      message = "Успех! Принес из вылазки: #{reward}"
      player.update!(raid_status: "returned_success", raid_outcome: message)

   when 40..59 # ВЕРНУЛСЯ НИ С ЧЕМ
      message = "Вернулся живым, но запасы в этом месте истощены. Ничего не нашел."
      player.update!(raid_status: "returned_empty", raid_outcome: message)

   when 15..39 # РАНЕНИЕ
      apply_injury(player)
      message = "Трагедия! Был ранен или заражен. Здоровье ухудшилось."
      player.update!(raid_status: "returned_injured", raid_outcome: message)

   else # СМЕРТЬ
      message = "Погиб во время выполнения задания. Группа видела, как обрушилось здание."
      player.update!(raid_status: "dead", eliminated: true, raid_outcome: message)
   end
    message # Возвращаем строку для лога
  end

  private

  def self.give_luggage(player, tier)
    card = Card.where(category: "luggage", tier: tier).where.not(id: player.cards.ids).order("RANDOM()").first
    if card
      PlayerCard.create!(player: player, card: card, revealed: true, bonus: true)
      card.name
    end
  end

  def self.give_action_card(player)
    ac = ActionCard.order("RANDOM()").first
    PlayerActionCard.create!(player: player, action_card: ac) if ac
  end

 def self.apply_injury(player)
    # Находим текущую карту здоровья игрока
    health_pc = player.player_cards.joins(:card).find_by(cards: { category: "health" })
    return unless health_pc

    # Проверяем, был ли игрок здоров или не обследован
    if health_pc.card.tags.include?("healthy") || health_pc.card.tags.include?("unknown")
      # Игрок был здоров -> ЗАМЕНЯЕМ карту на случайную плохую
      # Выбираем любую болезнь, кроме "Идеально здоров"
      bad_health_card = Card.where(category: "health")
                            .where.not("tags LIKE ?", "%healthy%")
                            .where.not("tags LIKE ?", "%unknown%")
                            .order("RANDOM()").first

      if bad_health_card
        health_pc.update!(card: bad_health_card, severity: 40)
      end
    else
      # Игрок уже был болен -> УВЕЛИЧИВАЕМ тяжесть
      current_severity = health_pc.severity || 20
      health_pc.update!(severity: [ current_severity + 30, 100 ].min)
    end
  end
end
