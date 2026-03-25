class Card < ApplicationRecord
  has_many :player_cards
  has_many :players, through: :player_cards

  # Категории карт
  validates :category, inclusion: { in: %w[profession health phobia luggage fact hobby] }

  # Удобно хранить теги (например, "medical, surgery") как массив
  def parsed_tags
    tags.to_s.split(",").map(&:strip)
  end
end
