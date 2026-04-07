class CreateRaids < ActiveRecord::Migration[8.0]
  def change
    create_table :raids do |t|
      t.string :name
      t.string :description
      t.string :required_tags
      t.string :dangerous_tags

      t.timestamps
    end
  end
end
