class FinalFixForGames < ActiveRecord::Migration[8.0]
  def change
    # Добавляем связь с угрозой, если её нет
    unless column_exists?(:games, :threat_id)
      add_reference :games, :threat, foreign_key: true
    end

    # Добавляем особенности бункера (json), если их нет
    unless column_exists?(:games, :bunker_features)
      add_column :games, :bunker_features, :jsonb, default: []
    end

    # Добавляем предметы бункера (строка), если их нет
    unless column_exists?(:games, :bunker_items)
      add_column :games, :bunker_items, :string
    end
  end
end
