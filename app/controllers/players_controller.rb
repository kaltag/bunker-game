class PlayersController < ApplicationController
  include GameFindable

  before_action :set_game
  before_action :set_player

  def show
    @player = @game.players.includes(player_cards: :card).find(@player.id)
  end

  def update
    if @player.update(player_params)
      redirect_to game_player_path(@game, @player)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def reveal_biology
    if @player.can_reveal_more?
      @player.update(biology_revealed: true)
      redirect_to game_player_path(@game, @player), notice: "Биология вскрыта!"
    else
      redirect_to game_player_path(@game, @player), alert: "Лимит вскрытий на этот раунд исчерпан!"
    end
  end

  def eliminate
    @player.update!(eliminated: true)
    redirect_to game_path(@game), notice: "Игрок #{@player.id} изгнан из бункера!"
  end

  private

  def player_params
    params.require(:player).permit(:name)
  end
end
