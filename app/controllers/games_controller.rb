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

  def reveal_next_round
    @game = Game.find(params[:id])

    # Изменение: теперь мы разрешаем переход с 5 на 6 раунд (Финал)
    if @game.current_round <= 5
      @game.increment!(:current_round)

      # Надежный способ обновить экраны всех игроков в реальном времени
      @game.players.each do |player|
        Turbo::StreamsChannel.broadcast_replace_to(
          player,
          target: "player_#{player.id}_screen",
          partial: "players/player_screen",
          locals: { player: player, game: @game }
        )
      end
    end

    redirect_to game_path(@game)
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
    # Выбираем случайный рейд
    raid = Raid.order("RANDOM()").first

    # Отправляем выбранных игроков (из чекбоксов)
    if params[:raider_ids].present?
      @game.players.update_all(raid_outcome: nil)
      players = @game.players.where(id: params[:raider_ids])
      players.update_all(raid_status: "raiding")
      @game.update!(active_raid_id: raid.id)

      # Обновляем экраны всех, чтобы увидеть, кто ушел
      Turbo::StreamsChannel.broadcast_refresh_to(@game)
      redirect_to game_path(@game), notice: "Группа отправилась в рейд: #{raid.name}!"
    else
      redirect_to game_path(@game), alert: "Выберите хотя бы одного добровольца!"
    end
  end

  # ОБНОВЛЯЕМ метод перехода в следующий раунд
  def reveal_next_round
    @game = Game.find(params[:id])

    # Если был активный рейд — подводим итоги ПЕРЕД переходом
    if @game.active_raid_id.present?
      raid = Raid.find(@game.active_raid_id)
      raiders = @game.players.where(raid_status: "raiding")

      raiders.each do |player|
        # Вызываем наш сервис из Шага 3
        RaidResolver.call(player, raid)
      end

      # Очищаем активный рейд
      @game.update!(active_raid_id: nil)
    end

    # Обычный переход к раунду
    if @game.current_round <= 5
      @game.increment!(:current_round)
      # ... здесь код broadcast_replace_to для игроков из прошлого шага ...
    end

    redirect_to game_path(@game)
  end
end
