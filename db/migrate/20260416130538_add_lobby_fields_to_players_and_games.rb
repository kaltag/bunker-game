class AddLobbyFieldsToPlayersAndGames < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :color, :string
    add_column :players, :avatar_emoji, :string
    add_column :games, :max_players, :integer, default: 8
  end
end
