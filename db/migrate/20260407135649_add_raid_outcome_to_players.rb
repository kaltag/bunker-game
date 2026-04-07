class AddRaidOutcomeToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :raid_outcome, :text
  end
end
