class AddBiologyRevealedToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :biology_revealed, :boolean, default: false
  end
end
