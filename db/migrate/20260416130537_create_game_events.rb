class CreateGameEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :game_events do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, foreign_key: true  # nil для системных событий
      t.integer :target_player_id
      t.string :event_type, null: false
      t.string :description, null: false
      t.integer :round

      t.timestamps
    end
    add_index :game_events, [:game_id, :created_at]
    add_foreign_key :game_events, :players, column: :target_player_id
  end
end
