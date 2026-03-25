class CleanupGamesAndAddRounds < ActiveRecord::Migration[8.0]
  def change
    # Удаляем старую строку, которая мешает ассоциации
    remove_column :games, :catastrophe, :string

    # Добавляем поле для текущего раунда (по умолчанию 1)
    add_column :games, :current_round, :integer, default: 1
  end
end
