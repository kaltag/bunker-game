class AddVisibilityToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :threat_revealed, :boolean
    add_column :games, :raid_params_revealed, :boolean
  end
end
