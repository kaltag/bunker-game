module GameFindable
  extend ActiveSupport::Concern

  included do
    helper_method :current_host?, :current_player?
  end

  private

  def set_game
    @game = Game.find(params[:game_id] || params[:id])
  end

  def set_player
    @player = @game.players.find(params[:player_id] || params[:id])
  end

  # --- Авторизация ---

  # Проверяет, что текущий пользователь — ведущий этой игры.
  # host_token сохраняется в session при создании игры.
  def require_host!
    unless host?
      redirect_to root_path, alert: "Только ведущий может выполнить это действие."
    end
  end

  # Проверяет, что текущий пользователь — владелец этого игрока.
  # player_id сохраняется в session при вводе имени.
  def require_own_player!
    unless own_player?
      redirect_to root_path, alert: "Вы не можете управлять чужим персонажем."
    end
  end

  # Ведущий тоже может действовать за игрока (например, eliminate)
  def require_host_or_own_player!
    unless host? || own_player?
      redirect_to root_path, alert: "Нет доступа."
    end
  end

  def host?
    session["host_#{@game.id}"] == @game.host_token
  end

  def own_player?
    @player && session["player_#{@player.id}"].present?
  end

  # Хелперы для views
  def current_host?
    @game && host?
  end

  def current_player?
    @player && own_player?
  end
end
