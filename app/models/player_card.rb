class PlayerCard < ApplicationRecord
  belongs_to :player, touch: true
  belongs_to :card
  after_commit -> { broadcast_refresh_to(player.game) }, on: :update


  broadcasts_refreshes
end
