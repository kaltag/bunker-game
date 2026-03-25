class PlayerCardsController < ApplicationController
  def reveal
    @game = Game.find(params[:game_id])
    @player = @game.players.find(params[:player_id])
    @player_card = @player.player_cards.find(params[:id])

    if @player.can_reveal_more?
      @player_card.update(revealed: true)
      redirect_to game_player_path(@game, @player), notice: "Карта вскрыта!"
    else
      redirect_to game_player_path(@game, @player), alert: "Лимит вскрытий на этот раунд исчерпан!"
    end
  end
end
