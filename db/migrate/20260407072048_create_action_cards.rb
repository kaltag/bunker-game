class CreateActionCards < ActiveRecord::Migration[8.0]
  def change
    create_table :action_cards do |t|
      t.string :name
      t.string :description
      t.string :card_type
      t.string :code
      t.boolean :requires_target

      t.timestamps
    end
  end
end
