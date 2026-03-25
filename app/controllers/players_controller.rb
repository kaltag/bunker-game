class PlayersController < ApplicationController
  def show
    @game = Game.find(params[:game_id])
    @player = @game.players.includes(player_cards: :card).find(params[:id])

    # Чтобы игрок случайно не подсмотрел чужие карты,
    # мы убеждаемся, что он открыл именно своего игрока из этой игры.
  end

  def reveal_biology
    @game = Game.find(params[:game_id])
    @player = @game.players.find(params[:id])

    if @player.can_reveal_more?
      @player.update(biology_revealed: true)
      redirect_to game_player_path(@game, @player), notice: "Биология вскрыта!"
    else
      redirect_to game_player_path(@game, @player), alert: "Лимит вскрытий на этот раунд исчерпан!"
    end
  end

  def eliminate
    @game = Game.find(params[:game_id])
    @player = @game.players.find(params[:id])

    # Помечаем как изгнанного
    @player.update!(eliminated: true)

    # МАГИЯ: Заставляем экраны Ведущего и ВСЕХ ИГРОКОВ мгновенно перезагрузиться
    Turbo::StreamsChannel.broadcast_refresh_to(@game)

    redirect_to game_path(@game), notice: "Игрок #{@player.id} изгнан из бункера!"
  end
end
