# app/services/raid_resolver.rb
class RaidResolver
  def self.call(player, raid)
    # 1. Собираем ВСЕ теги игрока как массив (точное совпадение, не подстрока)
    all_tags = player.cards.pluck(:tags).join(", ").split(/,\s*/).map(&:strip).reject(&:empty?)
    all_tags += player.profession&.tags.to_s.split(/,\s*/).map(&:strip).reject(&:empty?)
    all_tags.uniq!

    # 2. Рассчитываем модификатор навыков (точное совпадение тегов)
    score = 0
    raid.required_tags.to_s.split(", ").each { |t| score += 20 if all_tags.include?(t.strip) }
    raid.dangerous_tags.to_s.split(", ").each { |t| score -= 20 if all_tags.include?(t.strip) }

    # 3. Учитываем возраст и состояние
    score -= 15 if player.age > 60 || player.age < 20
    score -= 20 if player.health&.tags.to_s.split(/,\s*/).include?("disability")
    score += 10 if player.hobby&.tags.to_s.split(/,\s*/).include?("survival")

    # 4. Базовый бросок + score
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
    message
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
    health_pc = player.player_cards.joins(:card).find_by(cards: { category: "health" })
    return unless health_pc

    if health_pc.card.tags.to_s.split(/,\s*/).include?("healthy") ||
       health_pc.card.tags.to_s.split(/,\s*/).include?("unknown")
      bad_health_card = Card.where(category: "health")
                            .where.not("tags LIKE ?", "%healthy%")
                            .where.not("tags LIKE ?", "%unknown%")
                            .order("RANDOM()").first

      health_pc.update!(card: bad_health_card, severity: 40) if bad_health_card
    else
      current_severity = health_pc.severity || 20
      health_pc.update!(severity: [ current_severity + 30, 100 ].min)
    end
  end
end
