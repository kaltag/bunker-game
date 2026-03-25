class AddDetailsToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :bunker_items, :string
    add_column :games, :threat, :string
  end
end
