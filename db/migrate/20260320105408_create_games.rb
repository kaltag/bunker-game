class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :code
      t.string :catastrophe
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
