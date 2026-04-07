class PlayerActionCard < ApplicationRecord
  belongs_to :player
  belongs_to :action_card
end
