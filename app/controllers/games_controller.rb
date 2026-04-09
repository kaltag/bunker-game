class GamesController < ApplicationController
  def new
    @game = Game.new
  end

  def create
  # Берем количество из параметров, ограничиваем от 6 до 16 на всякий случай
  count = params[:player_count].to_i.clamp(6, 16)


  random_catastrophe = Catastrophe.order("RANDOM()").first

   # Создаем игру (здесь можно позже добавить выбор катастрофы из списка)
   @game = Game.create!(
    status: "preparing",
    catastrophe: random_catastrophe # Передаем объект катастрофы
  )

  # Запускаем генератор с нужным количеством игроков
  generator = GameGenerator.new(@game)
  generator.call(count)

  redirect_to game_path(@game), notice: "Партия на #{count} чел. готова!"
  end

  def show
    @game = Game.includes(:catastrophe).find(params[:id])
    @players = @game.players.includes(player_cards: :card)
  end

  def eliminate
    @game = Game.find(params[:game_id])
    @player = @game.players.find(params[:id])

    # Помечаем как изгнанного
    @player.update!(eliminated: true)

    # Отправляем красно-мигающий экран изгнания на телефон конкретно этого игрока
    Turbo::StreamsChannel.broadcast_replace_to(
      @player,
      target: "player_#{@player.id}_screen",
      partial: "players/player_screen",
      locals: { player: @player, game: @game }
    )

    redirect_to game_path(@game), notice: "Игрок #{@player.id} изгнан!"
  end

  def report
    @game = Game.includes(:catastrophe, players: { player_cards: :card }).find(params[:id])

    # Меняем статус игры на "завершена", если еще не поменяли
    @game.update(status: "finished")
  end

  def start_raid
    @game = Game.find(params[:id])
    raid = Raid.order("RANDOM()").first

    if params[:raider_ids].present?
      players = @game.players.where(id: params[:raider_ids])

      @game.players.update_all(raid_outcome: nil, raid_status: "at_home")

      players.each do |player|
        player.update!(raid_status: "raiding")
      end

      @game.update!(active_raid_id: raid.id)

      Turbo::StreamsChannel.broadcast_refresh_to(@game)

      redirect_to game_path(@game), notice: "Группа отправилась в рейд!"
    else
      redirect_to game_path(@game), alert: "Выберите хотя бы одного добровольца!"
    end
  end

  # ОБНОВЛЯЕМ метод перехода в следующий раунд
  def reveal_next_round
    @game = Game.find(params[:id])

    # 1. Сначала возвращаем игроков из рейда (если он был запущен)
    if @game.active_raid_id.present?
      raid = Raid.find(@game.active_raid_id)
      raiders = @game.players.where(raid_status: "raiding")

      raiders.each do |player|
        # Запускаем логику выживания для каждого
        RaidResolver.call(player, raid)
      end

      # Закрываем рейд в базе
      @game.update!(active_raid_id: nil, raid_params_revealed: false)
    end

    # 2. Увеличиваем раунд (до финала 6)
    if @game.current_round <= 5
      @game.update!(current_round: @game.current_round + 1)
    end

    redirect_to game_path(@game), notice: "Раунд обновлен, группа вернулась из вылазки!"
  end

  def reveal_threat
    @game = Game.find(params[:id])
    @game.update(threat_revealed: true)
    redirect_to game_path(@game)
  end

  def reveal_raid_system
    @game = Game.find(params[:id])
    @game.update(raid_params_revealed: true)
    redirect_to game_path(@game), notice: "Система рейдов активирована!"
  end
end
