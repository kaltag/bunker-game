class CreatePlayerCards < ActiveRecord::Migration[8.0]
  def change
    create_table :player_cards do |t|
      t.references :player, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.boolean :revealed, default: false

      t.timestamps
    end
  end
end
