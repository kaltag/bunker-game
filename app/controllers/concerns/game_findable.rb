module GameFindable
  extend ActiveSupport::Concern

  private

  def set_game
    @game = Game.find(params[:game_id] || params[:id])
  end

  def set_player
    @player = @game.players.find(params[:player_id] || params[:id])
  end
end
