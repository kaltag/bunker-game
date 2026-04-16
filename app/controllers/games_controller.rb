class GamesController < ApplicationController
  include GameFindable

  before_action :set_game, only: %i[show lobby start_game board report start_raid reveal_next_round reveal_threat reveal_raid_system clear_raid_report rematch fill_bots dev_reveal_all]
  before_action :require_host!, only: %i[show report start_game start_raid reveal_next_round reveal_threat reveal_raid_system clear_raid_report rematch fill_bots dev_reveal_all]

  def new
    @game = Game.new
  end

  def create
    count = params[:player_count].to_i.clamp(6, 16)
    catastrophe = Catastrophe.order("RANDOM()").first

    @game = Game.create!(status: "preparing", catastrophe: catastrophe, max_players: count)
    session["host_#{@game.id}"] = @game.host_token

    redirect_to lobby_game_path(@game)
  end

  # Лобби — публичное, и ведущий и игроки видят
  def lobby
    @players = @game.players.order(:created_at)
    @max_players = @game.max_players

    # Определяем, залогинен ли текущий игрок в этой игре
    @my_player = @game.players.find { |p| session["player_#{p.id}"] }
  end

  # Запуск игры — только ведущий
  def start_game
    if @game.players.count < 6
      redirect_to lobby_game_path(@game), alert: "Нужно минимум 6 игроков!"
      return
    end

    GameGenerator.new(@game).call(@game.players.count)
    @game.log_event!("game_started", "Игра началась! #{@game.players.count} игроков, вместимость: #{@game.bunker_capacity}")

    redirect_to game_path(@game), notice: "Партия запущена!"
  end

  def show
    redirect_to lobby_game_path(@game) and return if @game.preparing?
    @players = @game.players.includes(player_cards: :card).order(:id)
  end

  def board
    redirect_to lobby_game_path(@game) and return if @game.preparing?
    @players = @game.players.includes(player_cards: :card).order(:id)
  end

  def report
    @game = Game.includes(:catastrophe, :game_events, players: { player_cards: :card }).find(@game.id)

    unless @game.finished?
      @game.resolve_unknown_health!
      @game.update(status: "finished")
      @game.log_event!("game_finished", "Двери закрыты. Группа сформирована.")
    end
  end

  def start_raid
    raider_ids = Array(params[:raider_ids]).map(&:to_i).select(&:positive?)

    if raider_ids.any?
      raid = Raid.order("RANDOM()").first

      @game.players.update_all(raid_outcome: nil)
      raiders = @game.players.where(id: raider_ids)
      raiders.update_all(raid_status: "raiding")
      @game.update!(active_raid_id: raid.id, raid_candidate_ids: [])

      raider_names = raiders.pluck(:name).compact.join(", ")
      @game.log_event!("raid_started", "#{raider_names} отправились в рейд: #{raid.name}")

      Turbo::StreamsChannel.broadcast_refresh_to(@game)
      redirect_to game_path(@game), notice: "Группа отправилась в рейд!"
    else
      redirect_to game_path(@game), alert: "Выберите хотя бы одного добровольца!"
    end
  end

  def reveal_next_round
    @game.advance_round!
    @game.log_event!("round_advance", "Начался раунд #{@game.current_round}")

    # Логируем результаты рейда если были
    @game.players.where.not(raid_outcome: nil).where.not(raid_status: "raiding").each do |p|
      status_label = case p.raid_status
      when "returned_triumph" then "триумфально вернулся"
      when "returned_success" then "вернулся с добычей"
      when "returned_empty" then "вернулся ни с чем"
      when "returned_injured" then "вернулся с ранениями"
      when "dead" then "погиб на поверхности"
      else p.raid_status
      end
      @game.log_event!("raid_result", "#{p.display_name} #{status_label}", player: p)
    end

    redirect_to game_path(@game), notice: "Раунд обновлен!"
  end

  def reveal_threat
    @game.update(threat_revealed: true)
    @game.log_event!("threat_revealed", "Угроза активирована: #{@game.threat&.name}")
    redirect_to game_path(@game)
  end

  def reveal_raid_system
    candidate_ids = @game.active_players.order("RANDOM()").limit(3).pluck(:id)
    @game.update(raid_params_revealed: true, raid_candidate_ids: candidate_ids)
    redirect_to game_path(@game), notice: "Система рейдов активирована!"
  end

  def clear_raid_report
    @game.players.update_all(raid_outcome: nil)
    Turbo::StreamsChannel.broadcast_refresh_to(@game)
    redirect_to game_path(@game)
  end

  def rematch
    old_players = @game.players.select(:name, :color, :avatar_emoji).map(&:attributes)
    catastrophe = Catastrophe.order("RANDOM()").first

    new_game = Game.create!(status: "preparing", catastrophe: catastrophe, max_players: old_players.count)
    session["host_#{new_game.id}"] = new_game.host_token

    # Копируем игроков (имена, цвета, аватарки) — без карт
    old_players.each do |attrs|
      p = new_game.players.create!(name: attrs["name"], color: attrs["color"], avatar_emoji: attrs["avatar_emoji"])
      session["player_#{p.id}"] = true if session["player_#{@game.players.find_by(name: attrs['name'])&.id}"]
    end

    redirect_to lobby_game_path(new_game), notice: "Новая партия создана! Нажмите 'Старт' для генерации карт."
  end

  # DEV: заполнить пустые слоты ботами для тестирования
  def fill_bots
    return head(:forbidden) unless Rails.env.development?

    bot_names = %w[Алиса Борис Влад Галина Денис Елена Жора Зина Игорь Клара Леон Мария Нина Олег Полина Рома]
    empty_slots = @game.max_players - @game.players.count

    empty_slots.times do |i|
      name = (bot_names - @game.players.pluck(:name)).sample || "Бот#{i + 1}"
      color = @game.next_color
      emoji = (Player::AVATAR_EMOJIS - @game.players.pluck(:avatar_emoji).compact).sample || Player::AVATAR_EMOJIS.sample
      @game.players.create!(name: name, color: color, avatar_emoji: emoji)
    end

    Turbo::StreamsChannel.broadcast_refresh_to(@game)
    redirect_to lobby_game_path(@game), notice: "Добавлено #{empty_slots} ботов!"
  end

  # DEV: вскрыть все карты всех игроков + биологию
  def dev_reveal_all
    return head(:forbidden) unless Rails.env.development?

    @game.players.each do |p|
      p.player_cards.update_all(revealed: true)
      p.update!(biology_revealed: true)
    end

    Turbo::StreamsChannel.broadcast_refresh_to(@game)
    redirect_to game_path(@game), notice: "DEV: Все карты вскрыты!"
  end
end
