class AddRaidStatusToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :raid_status, :string, default: 'at_home'
  end
end
