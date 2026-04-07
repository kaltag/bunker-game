# app/services/game_generator.rb
class GameGenerator
  PLAYER_COUNT = 8

  def initialize(game)
    @game = game
    @available_cards = load_cards
  end

  def call(player_count = PLAYER_COUNT)
    @game.players.destroy_all

    capacity = (player_count / 2).to_i

    # Взвешенная генерация срока в бункере (в процентах)
    duration_roll = rand(1..100)
    duration = case duration_roll
    when 1..50 then 5
    when 51..70 then 2
    when 71..90 then 10
    when 91..95 then 15
    when 96..99 then 20
    else 50
    end

    # Выбираем 2 случайные особенности бункера
    selected_features = BunkerFeature.order("RANDOM()").limit(2)

    # Формируем массив данных для хранения
    features_data = selected_features.map { |f| { name: f.name, description: f.description } }


    # угрозы (происшествия в середине игры)
    threat = Threat.order("RANDOM()").first


    # 2. Генерируем условия бункера
    @game.update!(
        bunker_capacity: capacity,
        bunker_duration: duration,
        bunker_supplies: [ "Запасов еды хватит на весь срок", "Еды хватит только на половину срока", "Критический дефицит продовольствия" ].sample,
        bunker_size: [ "Просторный", "Тесный", "Средний" ].sample,
        bunker_features: features_data,
        threat: threat,
        current_round: 1,
        status: "in_progress"
    )

    # Создаем игроков с учетом демографической квоты (мин. 2М и 2Ж)
    players = create_players(player_count)

    # Этап 1: Раздаем уникальные профессии
    assign_unique_cards(players, "profession")

    # Этап 2: Выдаем гарантированные "пустые" карты (Здоровье и Фобии)
    # assign_guaranteed_traits(players)

    # Этап 2: Выдаем карты особых условий/действий всем игрокам
    assign_action_cards(players)

    # Этап 3: Создаем динамические синергии (случайный набор на партию)
    inject_dynamic_synergies(players)

    # Этап 4: Раздаем остальные карты, стараясь балансировать "вес" игроков
    assign_balanced_cards(players, "health")
    assign_balanced_cards(players, "luggage")
    assign_balanced_cards(players, "hobby")
    assign_balanced_cards(players, "fact")
    assign_balanced_cards(players, "phobia")
  end

  private

  # Загружаем все карты в память один раз
  def load_cards
    Card.all.group_by(&:category)
  end

  # Создаем игроков с соблюдением баланса полов
  def create_players(count)
    # Гарантируем минимум 2 М и 2 Ж
    genders = [ "Мужчина", "Мужчина", "Женщина", "Женщина" ]

    # Остальных добиваем рандомом
    (count - 4).times { genders <<[ "Мужчина", "Женщина" ].sample }
    genders.shuffle! # Перемешиваем, чтобы они не шли по порядку

    Array.new(count) do |i|
      # Создаем игрока, передавая ему пол (возраст и остальное сгенерирует callback модели)
      @game.players.create!(gender: genders[i])
    end
  end

  # Гарантируем минимум 1 абсолютно здоровых и 1 без фобий
  def assign_guaranteed_traits(players)
    healthy_card = @available_cards["health"].find { |c| c.tags.include?("healthy") }
    no_phobia_card = @available_cards["phobia"].find { |c| c.tags.include?("brave") }

    # Выбираем 1 случайных игроков и даем им здоровье
    players.sample(1).each do |player|
      add_card_to_player(player, healthy_card) if healthy_card
    end

    # Выбираем 1 случайных игроков (могут совпасть со здоровыми) и убираем им фобии
    players.sample(1).each do |player|
      add_card_to_player(player, no_phobia_card) if no_phobia_card
    end
  end

  # Раздаем уникальные карты из одной категории (для профессий)
  def assign_unique_cards(players, category)
    cards = @available_cards[category].sample(players.count)
    players.zip(cards).each do |player, card|
      add_card_to_player(player, card) if card
    end
  end

  # --- БЛОК СИНЕРГИЙ ---
  # Запускаем от 2 до 4 случайных синергий за партию, чтобы каждая игра была уникальной
  def inject_dynamic_synergies(players)
    min_s = (players.count / 4).to_i
    max_s = (players.count / 2).to_i

    possible_synergies =[
      -> { synergy_medical(players) },
      -> { synergy_psychological(players) },
      -> { synergy_farming(players) },
      -> { synergy_engineering(players) },
      -> { synergy_security(players) },
      -> { synergy_alcohol(players) },
      -> { synergy_chemist_addict(players) },
      -> { synergy_cook_supplies(players) },
      -> { synergy_hacker_gadget(players) },
      -> { synergy_entertainment(players) },
      -> { synergy_criminal_lockpick(players) }
    ]

    # Выбираем случайное количество синергий и запускаем их
    possible_synergies.sample(rand(min_s..max_s)).each(&:call)
  end

  # 1. Врач + Излечимый больной (односторонняя)
  def synergy_medical(players)
    doctor = players.find { |p| p.profession&.tags.to_s.include?("medical") }
    patient = players.reject { |p| p == doctor || p.cards.any? { |c| c.category == "health" } }.sample
    if doctor && patient
      disease = @available_cards["health"].select { |c| c.is_curable && c.weight < 0 }.sample
      add_card_to_player(patient, disease)
    end
  end

  # 2. Психолог + Тяжелая фобия/расстройство (односторонняя)
  def synergy_psychological(players)
    psychologist = players.find { |p| p.profession&.tags.to_s.include?("mental_health") }
    patient = players.reject { |p| p == psychologist || p.cards.any? { |c| c.category == "phobia" } }.sample
    if psychologist && patient
      phobia = @available_cards["phobia"].select { |c| c.tags.to_s.include?("panic") && c.weight < 0 }.sample
      add_card_to_player(patient, phobia)
    end
  end

  # 3. Фермер + Семена/Саженцы (двусторонняя)
  def synergy_farming(players)
    farmer = players.find { |p| p.profession&.tags.to_s.include?("agriculture") }
    partner = players.reject { |p| p == farmer || p.cards.any? { |c| c.category == "luggage" } }.sample
    if farmer && partner
      seeds = @available_cards["luggage"].find { |c| c.tags.to_s.include?("farming") }
      add_card_to_player(partner, seeds) if seeds
    end
  end

  # 4. Инженер/Электрик + Инструменты (двусторонняя)
  def synergy_engineering(players)
    engineer = players.find { |p| p.profession&.tags.to_s.include?("technical") }
    partner = players.reject { |p| p == engineer || p.cards.any? { |c| c.category == "luggage" } }.sample
    if engineer && partner
      tools = @available_cards["luggage"].select { |c| c.tags.to_s.include?("repair") }.sample
      add_card_to_player(partner, tools) if tools
    end
  end

  # 5. Военный/Полицейский + Оружие (Синергия с самим собой или партнером)
  def synergy_security(players)
    security = players.find { |p| p.profession&.tags.to_s.include?("security") }
    target = [ security, players.sample ].sample # 50% шанс, что оружие будет у него самого
    if security && target && target.cards.none? { |c| c.category == "luggage" }
      weapon = @available_cards["luggage"].select { |c| c.tags.to_s.include?("weapon") }.sample
      add_card_to_player(target, weapon) if weapon
    end
  end

  # 6. Производитель алкоголя + Алкоголик (Опасная синергия)
  def synergy_alcohol(players)
    brewer = players.find { |p| p.profession&.tags.to_s.include?("alcohol") || p.cards.any? { |c| c.tags.to_s.include?("alcohol") } }
    addict = players.reject { |p| p == brewer || p.cards.any? { |c| c.category == "health" } }.sample
    if brewer && addict
      alcoholism = @available_cards["health"].find { |c| c.name == "Алкоголизм" }
      add_card_to_player(addict, alcoholism) if alcoholism
    end
  end

  # 7. НОВАЯ: Химик/Ученый + Наркозависимый (Драматичная)
  def synergy_chemist_addict(players)
    chemist = players.find { |p| p.profession&.tags.to_s.match?(/chemical|science/) }
    addict = players.reject { |p| p == chemist || p.cards.any? { |c| c.category == "health" } }.sample
    if chemist && addict
      drugs = @available_cards["health"].find { |c| c.name.include?("Зависимость") }
      add_card_to_player(addict, drugs) if drugs
    end
  end

  # 8. НОВАЯ: Повар + Еда в багаже (Двусторонняя)
  def synergy_cook_supplies(players)
    cook = players.find { |p| p.profession&.tags.to_s.include?("food") }
    partner = players.reject { |p| p == cook || p.cards.any? { |c| c.category == "luggage" } }.sample
    if cook && partner
      food_luggage = @available_cards["luggage"].select { |c| c.tags.to_s.include?("food") }.sample
      add_card_to_player(partner, food_luggage) if food_luggage
    end
  end

  # 9. НОВАЯ: Хакер/Программист + Ноутбук и платы (Для себя или соседа)
  def synergy_hacker_gadget(players)
    hacker = players.find { |p| p.profession&.tags.to_s.include?("software") }
    target = [ hacker, players.sample ].sample
    if hacker && target && target.cards.none? { |c| c.category == "luggage" }
      laptop = @available_cards["luggage"].find { |c| c.name.include?("Ноутбук") }
      add_card_to_player(target, laptop) if laptop
    end
  end

  # 10. НОВАЯ: Творческий человек + Депрессия (Поддержка морали)
  def synergy_entertainment(players)
    entertainer = players.find { |p| p.profession&.tags.to_s.match?(/art|social/) }
    depressed = players.reject { |p| p == entertainer || p.cards.any? { |c| c.category == "health" } }.sample
    if entertainer && depressed
      depression = @available_cards["health"].find { |c| c.name.include?("Депрессия") || c.name.include?("Суицидальные") }
      add_card_to_player(depressed, depression) if depression

      # Даем гитару или настолки самому творческому, если у него еще нет багажа
      if entertainer.cards.none? { |c| c.category == "luggage" }
        fun_luggage = @available_cards["luggage"].select { |c| c.tags.to_s.include?("social") || c.tags.to_s.include?("mental") }.sample
        add_card_to_player(entertainer, fun_luggage) if fun_luggage
      end
    end
  end

  # 11. НОВАЯ: Криминал + Отмычки (Тайная синергия)
  def synergy_criminal_lockpick(players)
    thief = players.reject { |p| p.cards.any? { |c| c.category == "fact" } }.sample
    target = players.reject { |p| p == thief || p.cards.any? { |c| c.category == "luggage" } }.sample
    if thief && target
      criminal_fact = @available_cards["fact"].select { |c| c.tags.to_s.include?("criminal") }.sample
      lockpicks = @available_cards["luggage"].find { |c| c.name.include?("отмычек") }
      add_card_to_player(thief, criminal_fact) if criminal_fact
      add_card_to_player(target, lockpicks) if lockpicks
    end
  end
  # --- КОНЕЦ БЛОКА СИНЕРГИЙ ---

  # Раздаем остальные карты, стараясь выровнять "вес" игроков
  def assign_balanced_cards(players, category)
    cards_pool = @available_cards[category].shuffle

    players.each do |player|
      # Пропускаем, если у игрока уже есть карта этой категории (выдана по гарантии или синергии)
      next if player.cards.any? { |c| c.category == category }

      card = find_balancing_card(cards_pool, player)
      add_card_to_player(player, card)

      # Удаляем карту из пула, чтобы она не дублировалась (КРОМЕ базовых карт "Здоров"
      # и "Нет фобий", их можно дублировать) || card.tags.include?("brave") "Нет фобий" пока убрали дублирование
      unless card.tags.include?("healthy")
        cards_pool.delete(card)
      end
    end
  end

  # Подбираем карту, чтобы КП игрока стремился к нулю
  def find_balancing_card(cards_pool, player)
    current_weight = player.cards.sum(&:weight)

    # Сортируем карты по тому, насколько они подходят к 0
    sorted_cards = cards_pool.sort_by { |card| (current_weight + card.weight).abs }

    # Вместо того чтобы всегда брать самую первую (идеальную),
    # берем одну из 2-х лучших, чтобы добавить вариативности.
    sorted_cards.first(2).sample
  end

  # Добавляем карту игроку, учитывая правила тяжести болезней
  def add_card_to_player(player, card)
    return unless card

    severity = nil

    # Генерируем проценты ТОЛЬКО для болезней, исключая "Абсолютно здоров" и "Не обследовался"
    if card.category == "health" && !card.tags.include?("healthy") && !card.tags.include?("unknown")
      severity = rand(2..18) * 5 # Генерируем тяжесть от 10% до 90%
    end

    PlayerCard.create!(player: player, card: card, severity: severity, revealed: false)
    player.reload # Обновляем объект в памяти
  end

  # Выдаем каждому игроку по 1 случайной карте действий
  def assign_action_cards(players)
    action_cards = ActionCard.order("RANDOM()").limit(players.count)
    players.zip(action_cards).each do |player, ac|
      PlayerActionCard.create!(player: player, action_card: ac) if ac
    end
  end
end
