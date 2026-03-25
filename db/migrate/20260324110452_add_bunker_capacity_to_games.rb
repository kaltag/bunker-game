class AddBunkerCapacityToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :bunker_capacity, :integer
  end
end
