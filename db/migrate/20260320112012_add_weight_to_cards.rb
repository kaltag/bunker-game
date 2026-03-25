class AddWeightToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :weight, :integer
  end
end
