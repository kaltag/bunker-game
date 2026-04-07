class AddActiveRaidToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :active_raid_id, :integer
  end
end
