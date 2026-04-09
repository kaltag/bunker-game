class Player < ApplicationRecord
  belongs_to :game, touch: true
  has_many :player_cards, dependent: :destroy
  has_many :cards, through: :player_cards
  has_many :player_action_cards, dependent: :destroy
  after_commit -> { broadcast_refresh_to(game) }, on: :update

  broadcasts_refreshes

  # Колбэк: срабатывает прямо перед созданием игрока в базе
  before_create :generate_biological_stats

  # Удобные методы для карточек
  def profession
    cards.find_by(category: "profession")
  end

  def health
    cards.find_by(category: "health")
  end

  def luggage
    cards.find_by(category: "luggage")
  end

  def phobia
    cards.find_by(category: "phobia")
  end

  def hobby
    cards.find_by(category: "hobby")
  end

  def fact
    cards.find_by(category: "fact")
  end

  def all_luggage
    cards.where(category: "luggage")
  end

  def all_action_cards
    action_cards # через связь has_many :action_cards, through: :player_action_cards
  end

  def ordered_player_cards
    # Определяем желаемый порядок категорий
    category_order = [ "profession", "health", "phobia", "hobby", "luggage", "fact" ]

    # Сортируем карточки игрока согласно этому списку
    player_cards.joins(:card).sort_by do |pc|
      category_order.index(pc.card.category) || 99
    end
  end

  # Сколько всего категорий сейчас открыто у игрока
  def total_revealed_count
    count = player_cards.where(revealed: true).count
    count += 1 if biology_revealed
    count
  end

  # Разрешено ли игроку открыть карту в ТЕКУЩЕМ раунде?
  # Формула: (Номер раунда + 1). В 1 раунде = 2 карты, во 2 = 3 карты и т.д.
  def can_reveal_more?
     return false if eliminated # Изгнанные ничего не вскрывают
    total_revealed_count < (game.current_round + 1)
  end

  def show_prof_exp?
    biology_revealed
  end

  def show_hobby_exp?
    biology_revealed
  end

  private

  def generate_biological_stats
    # 1. Генерируем Пол и Возраст (если они еще не заданы)
    self.gender ||= [ "Мужчина", "Женщина" ].sample
    self.age ||= rand(18..75)

    # 2. Рассчитываем Бесплодие (Чайлдфри / Биологическое)
    self.is_infertile = calculate_infertility

    # 3. Рассчитываем стаж (зависит от возраста)
    # Считаем, что человек начинает работать/увлекаться хобби с 18 лет
    working_years =[ self.age - 16, 0 ].max

    # Стаж профессии: максимум это working_years, но может быть меньше (учился, менял работу)
    self.profession_experience ||=[ working_years - rand(0..7), 0 ].max

    # Стаж хобби: может быть меньше, так как хобби появляются позже
    self.hobby_experience ||= [ working_years - rand(0..15), 0 ].max
  end

  def calculate_infertility
    # 100% бесплодие от старости
    if self.gender == "Женщина" && self.age >= 60
      return true
    elsif self.gender == "Мужчина" && self.age >= 75
      return true
    end

    # Для остальных: 10% шанс случайного бесплодия (болезнь/генетика)
    rand(1..100) <= 10
  end
end
