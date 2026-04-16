class GameEvent < ApplicationRecord
  belongs_to :game
  belongs_to :player, optional: true
  belongs_to :target_player, class_name: "Player", optional: true

  validates :event_type, presence: true
  validates :description, presence: true

  scope :chronological, -> { order(:created_at) }
  scope :for_round, ->(r) { where(round: r) }
end
