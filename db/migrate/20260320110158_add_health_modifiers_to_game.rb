class AddHealthModifiersToGame < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :is_curable, :boolean, default: true
    add_column :player_cards, :severity, :integer
  end
end
