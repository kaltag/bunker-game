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
end
