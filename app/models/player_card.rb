class PlayerCard < ApplicationRecord
  belongs_to :player
  belongs_to :card

  # Отправляем обновление карточки игрока на пульт ведущего
  after_update_commit -> {
    broadcast_replace_to player.game,
    target: "host_player_#{player.id}",
    partial: "players/host_card",
    locals: { player: player }
  }
end
