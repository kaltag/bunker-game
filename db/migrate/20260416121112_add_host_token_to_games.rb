class AddHostTokenToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :host_token, :string, null: false, default: -> { "upper(substr(md5(random()::text), 1, 16))" }
    add_index :games, :host_token, unique: true
  end
end
