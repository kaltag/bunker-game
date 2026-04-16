class PlayerCardsController < ApplicationController
  include GameFindable

  before_action :set_game
  before_action :set_player
  before_action :require_own_player!

  def reveal
    @player_card = @player.player_cards.find(params[:id])

    if @player.can_reveal_more?
      @player_card.update(revealed: true)
      card = @player_card.card
      detail = card.name
      detail += " (#{@player_card.severity}%)" if card.category == "health" && @player_card.severity
      @game.log_event!("card_reveal", "#{@player.display_name} вскрыл #{card.category} — #{detail}", player: @player)
      redirect_to game_player_path(@game, @player), notice: "Карта вскрыта!"
    else
      redirect_to game_player_path(@game, @player), alert: "Лимит вскрытий на этот раунд исчерпан!"
    end
  end
end
