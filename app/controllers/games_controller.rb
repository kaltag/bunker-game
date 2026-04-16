class GamesController < ApplicationController
  include GameFindable

  before_action :set_game, only: %i[show report start_raid reveal_next_round reveal_threat reveal_raid_system clear_raid_report]

  def new
    @game = Game.new
  end

  def create
    count = params[:player_count].to_i.clamp(6, 16)
    random_catastrophe = Catastrophe.order("RANDOM()").first

    @game = Game.create!(status: "preparing", catastrophe: random_catastrophe)
    GameGenerator.new(@game).call(count)

    redirect_to game_path(@game), notice: "Партия на #{count} чел. готова!"
  end

  def show
    @players = @game.players.includes(player_cards: :card)
  end

  def report
    @game = Game.includes(:catastrophe, players: { player_cards: :card }).find(@game.id)
    @game.update(status: "finished")
  end

  def start_raid
    if params[:raider_ids].present?
      raid = Raid.order("RANDOM()").first

      @game.players.update_all(raid_outcome: nil)
      @game.players.where(id: params[:raider_ids]).update_all(raid_status: "raiding")
      @game.update!(active_raid_id: raid.id)

      # update_all не запускает колбэки — ручной broadcast обязателен
      Turbo::StreamsChannel.broadcast_refresh_to(@game)

      redirect_to game_path(@game), notice: "Группа отправилась в рейд!"
    else
      redirect_to game_path(@game), alert: "Выберите хотя бы одного добровольца!"
    end
  end

  def reveal_next_round
    @game.advance_round!
    redirect_to game_path(@game), notice: "Раунд обновлен, группа вернулась из вылазки!"
  end

  def reveal_threat
    @game.update(threat_revealed: true)
    redirect_to game_path(@game)
  end

  def reveal_raid_system
    @game.update(raid_params_revealed: true)
    redirect_to game_path(@game), notice: "Система рейдов активирована!"
  end

  def clear_raid_report
    @game.players.update_all(raid_outcome: nil)
    Turbo::StreamsChannel.broadcast_refresh_to(@game)
    redirect_to game_path(@game)
  end
end
