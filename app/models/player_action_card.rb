class PlayerActionCard < ApplicationRecord
  belongs_to :player, touch: true
  belongs_to :action_card
end
