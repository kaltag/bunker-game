class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.references :game, null: false, foreign_key: true
      t.string :name
      t.string :gender
      t.integer :age
      t.boolean :survived, default: false

      t.timestamps
    end
  end
end
