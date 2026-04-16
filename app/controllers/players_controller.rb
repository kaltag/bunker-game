class PlayersController < ApplicationController
  include GameFindable

  before_action :set_game
  before_action :set_player, only: %i[show update reveal_biology eliminate]
  before_action :require_own_player!, only: %i[reveal_biology]
  before_action :require_host!, only: %i[eliminate]

  def show
    redirect_to lobby_game_path(@game) and return if @game.preparing?
    @player = @game.players.includes(player_cards: :card).find(@player.id)
  end

  # Создание игрока в лобби (POST из формы лобби)
  def create
    if @game.lobby_full?
      redirect_to lobby_game_path(@game), alert: "Все слоты заняты!"
      return
    end

    unless @game.preparing?
      redirect_to lobby_game_path(@game), alert: "Игра уже началась!"
      return
    end

    name = player_params[:name].to_s.strip
    if name.length < 2 || name.length > 30
      redirect_to lobby_game_path(@game), alert: "Имя должно быть от 2 до 30 символов."
      return
    end

    color = @game.next_color
    emoji = params[:avatar_emoji].presence || Player::AVATAR_EMOJIS.sample

    player = @game.players.create!(name: name, color: color, avatar_emoji: emoji)
    session["player_#{player.id}"] = true

    @game.log_event!("player_joined", "#{player.name} присоединился к игре", player: player)
    Turbo::StreamsChannel.broadcast_refresh_to(@game)

    redirect_to lobby_game_path(@game), notice: "Добро пожаловать, #{player.name}!"
  end

  def update
    if @player.name.blank?
      name = player_params[:name].to_s.strip
      if name.length < 2 || name.length > 30
        redirect_to game_player_path(@game, @player), alert: "Имя должно быть от 2 до 30 символов."
        return
      end

      if @player.update(name: name)
        session["player_#{@player.id}"] = true
        redirect_to game_player_path(@game, @player)
      else
        render :show, status: :unprocessable_entity
      end
    elsif own_player?
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
      bio_text = "#{@player.gender}, #{@player.age} лет, #{@player.is_infertile ? 'бесплоден' : 'фертилен'}"
      @game.log_event!("biology_reveal", "#{@player.display_name} вскрыл биологию: #{bio_text}", player: @player)
      redirect_to game_player_path(@game, @player), notice: "Биология вскрыта!"
    else
      redirect_to game_player_path(@game, @player), alert: "Лимит вскрытий на этот раунд исчерпан!"
    end
  end

  def eliminate
    @player.update!(eliminated: true)
    @game.log_event!("player_eliminated", "#{@player.display_name} изгнан из бункера", player: @player)
    redirect_to game_path(@game), notice: "Игрок #{@player.display_name} изгнан из бункера!"
  end

  private

  def player_params
    params.require(:player).permit(:name)
  end
end
