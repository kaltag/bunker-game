class PlayerCard < ApplicationRecord
  belongs_to :player, touch: true
  belongs_to :card
end
