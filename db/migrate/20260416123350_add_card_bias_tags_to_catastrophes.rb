class AddCardBiasTagsToCatastrophes < ActiveRecord::Migration[8.0]
  def change
    add_column :catastrophes, :card_bias_tags, :string
  end
end
