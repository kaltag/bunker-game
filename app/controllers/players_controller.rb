class PlayersController < ApplicationController
  include GameFindable

  before_action :set_game
  before_action :set_player
  before_action :require_own_player!, only: %i[reveal_biology]
  before_action :require_host!, only: %i[eliminate]

  def show
    @player = @game.players.includes(player_cards: :card).find(@player.id)
  end

  def update
    # Ввод имени — "клейм" персонажа. Первый кто вводит имя, привязывает этого игрока к своей сессии.
    if @player.name.blank?
      name = player_params[:name].to_s.strip
      if name.length < 2 || name.length > 30
        redirect_to game_player_path(@game, @player), alert: "Имя должно быть от 2 до 30 символов."
        return
      end

      if @player.update(name: name)
        # Привязка игрока к session — теперь только этот браузер может управлять персонажем
        session["player_#{@player.id}"] = true
        redirect_to game_player_path(@game, @player)
      else
        render :show, status: :unprocessable_entity
      end
    elsif own_player?
      # Только владелец может менять имя после первого ввода
      if @player.update(player_params)
        redirect_to game_player_path(@game, @player)
      else
        render :show, status: :unprocessable_entity
      end
    else
      redirect_to game_player_path(@game, @player), alert: "Этот персонаж уже занят другим игроком."
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
    redirect_to game_path(@game), notice: "Игрок #{@player.display_name} изгнан из бункера!"
  end

  private

  def player_params
    params.require(:player).permit(:name)
  end
end
