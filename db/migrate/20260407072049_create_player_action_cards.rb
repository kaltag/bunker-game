class CreatePlayerActionCards < ActiveRecord::Migration[8.0]
  def change
    create_table :player_action_cards do |t|
      t.references :player, null: false, foreign_key: true
      t.references :action_card, null: false, foreign_key: true
      t.boolean :used, default: false

      t.timestamps
    end
  end
end
