class AddBonusToPlayerCards < ActiveRecord::Migration[8.0]
  def change
    add_column :player_cards, :bonus, :boolean, default: false, null: false
  end
end
