class AddBioStatsToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :is_infertile, :boolean
    add_column :players, :profession_experience, :integer
    add_column :players, :hobby_experience, :integer
  end
end
