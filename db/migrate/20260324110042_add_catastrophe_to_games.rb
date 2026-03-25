class AddCatastropheToGames < ActiveRecord::Migration[8.0]
  def change
    add_reference :games, :catastrophe, null: false, foreign_key: true
    add_column :games, :bunker_duration, :integer
    add_column :games, :bunker_supplies, :string
    add_column :games, :bunker_size, :string
  end
end
