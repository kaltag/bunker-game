class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.string :category
      t.string :name
      t.string :tier
      t.text :description
      t.string :tags

      t.timestamps
    end
  end
end
