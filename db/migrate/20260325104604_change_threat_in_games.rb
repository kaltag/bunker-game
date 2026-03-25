class ChangeThreatInGames < ActiveRecord::Migration[8.0]
  def change
    remove_column :games, :threat, :string
    add_reference :games, :threat, foreign_key: true
  end
end
