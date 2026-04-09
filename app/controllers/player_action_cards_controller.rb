# app/controllers/player_action_cards_controller.rb
class PlayerActionCardsController < ApplicationController
  def use
    @game = Game.find(params[:game_id])
    @player = @game.players.find(params[:player_id])
    @player_action_card = @player.player_action_cards.find(params[:id])
    action_card = @player_action_card.action_card

    target = @game.players.find(params[:target_id]) if params[:target_id].present?

    # Проверка от двойного использования или использования мертвецом
    unless @player_action_card.used || @player.eliminated

      # Получаем всех живых игроков (пригодится для массовых карт)
      active_players = @game.players.where(eliminated: false)

      # === МАГИЯ АВТОМАТИЗАЦИИ ===
      case action_card.code

      # 1. Точечные лечения
      when "heal_health"
        if target
          healthy_card = Card.find_by(category: "health", name: "Идеально здоров")
          target_health = target.player_cards.joins(:card).find_by(cards: { category: "health" })
          target_health.update!(card: healthy_card, severity: 0) if target_health
        end

      when "heal_phobia"
        if target
          brave_card = Card.find_by(category: "phobia", name: "Нет фобий")
          target_phobia = target.player_cards.joins(:card).find_by(cards: { category: "phobia" })
          target_phobia.update!(card: brave_card) if target_phobia
        end

      # 2. Точечные замены (сброс старой карты и выдача новой)
      when "reroll_profession"
        if target
          new_prof = Card.where(category: "profession").order("RANDOM()").first
          target_prof = target.player_cards.joins(:card).find_by(cards: { category: "profession" })
          target_prof.update!(card: new_prof) if target_prof
        end

      when "reroll_health"
        if target
          new_health = Card.where(category: "health").order("RANDOM()").first
          target_health = target.player_cards.joins(:card).find_by(cards: { category: "health" })
          severity = (new_health.tags.include?("healthy") || new_health.tags.include?("unknown")) ? 0 : rand(2..18) * 5
          target_health.update!(card: new_health, severity: severity) if target_health
        end

      # 3. ГЛОБАЛЬНЫЕ СМЕНЫ: Профориентация
      when "reroll_all_professions"
        # Берем из базы нужное количество уникальных профессий
        new_professions = Card.where(category: "profession").order("RANDOM()").limit(active_players.count).to_a

        active_players.each do |p|
          prof_card = p.player_cards.joins(:card).find_by(cards: { category: "profession" })
          # Берем первую профессию из пула (и удаляем её оттуда)
          prof_card.update!(card: new_professions.pop) if prof_card && new_professions.any?
        end

      # 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕШИВАНИЯ (Начистоту)
      when "shuffle_luggage", "shuffle_health", "shuffle_hobbies", "shuffle_facts"
        # Определяем категорию по коду
        category = action_card.code.split("_").last
        category = "hobby" if category == "hobbies"
        category = "fact" if category == "facts"

        # Ищем все PlayerCard этой категории у ЖИВЫХ игроков, которые ОТКРЫТЫ
        revealed_pcs = PlayerCard.joins(:player, :card).where(players: { id: active_players.pluck(:id) }, cards: { category: category }, revealed: true).to_a

        if revealed_pcs.count > 1
          # Сохраняем ID карт и тяжесть в массив и перемешиваем
          shuffled_data = revealed_pcs.map { |pc| { card_id: pc.card_id, severity: pc.severity } }.shuffle

          # Раздаем обратно
          revealed_pcs.each_with_index do |pc, index|
            pc.update!(card_id: shuffled_data[index][:card_id], severity: shuffled_data[index][:severity])
          end
        end

      when "shuffle_biology"
        # Находим живых игроков, у которых открыта биология
        bio_players = active_players.where(biology_revealed: true).to_a
        if bio_players.count > 1
          # Собираем их биологию и перемешиваем
          shuffled_bio = bio_players.map { |p| { gender: p.gender, age: p.age, is_infertile: p.is_infertile } }.shuffle

          bio_players.each_with_index do |p, index|
            p.update!(shuffled_bio[index])
          end
        end

      # 5. ОБМЕНЫ КАРТАМИ С СОСЕДОМ
      when "swap_luggage", "swap_health", "swap_hobbies", "swap_facts"
        category = action_card.code.split("_").last
        category = "hobby" if category == "hobbies"
        category = "fact" if category == "facts"

        if target
          my_pc = @player.player_cards.joins(:card).find_by(cards: { category: category })
          target_pc = target.player_cards.joins(:card).find_by(cards: { category: category })

          if my_pc && target_pc
            # Запоминаем свои данные
            my_card_id, my_severity = my_pc.card_id, my_pc.severity

            # Отдаем свои карты цели, а карты цели забираем себе
            my_pc.update!(card_id: target_pc.card_id, severity: target_pc.severity)
            target_pc.update!(card_id: my_card_id, severity: my_severity)
          end
        end

      when "increase_capacity"
        @game.increment!(:bunker_capacity)

      when "decrease_capacity"
        @game.decrement!(:bunker_capacity) if @game.bunker_capacity > 1

      when "cure_infertility"
        target.update!(is_infertile: false) if target

      when "make_young"
        if target
          new_age = rand(18..25)
          target.update!(age: new_age, is_infertile: false)
        end

      when "reveal_all"
        if target
          target.player_cards.update_all(revealed: true)
          target.update!(biology_revealed: true)
        end

      when "steal_luggage"
        if target
          target_luggage = target.player_cards.joins(:card).find_by(cards: { category: "luggage" })
          if target_luggage
            # Меняем владельца карты багажа на текущего игрока
            target_luggage.update!(player: @player, revealed: true)
          end
        end

        # СОЦИАЛЬНЫЕ КАРТЫ: Ничего в базе не меняют, только помечаются использованными.
        # Игроки отыгрывают их вживую за столом (например, "Громкий голос").
      end
      # ==========================

      # Помечаем карту как использованную
      @player_action_card.update!(used: true)

      # Обновляем пульт Ведущего и экраны ВСЕХ игроков
      Turbo::StreamsChannel.broadcast_refresh_to(@game)
      @game.players.each do |p|
        Turbo::StreamsChannel.broadcast_replace_to(
          p, target: "player_#{p.id}_screen", partial: "players/player_screen", locals: { player: p, game: @game }
        )
      end
    end

    redirect_to game_player_path(@game, @player)
  end
end
