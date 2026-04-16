# db/seeds.rb
puts "Полная очистка старых данных..."
ActiveRecord::Base.connection.execute("TRUNCATE games, players, player_cards, cards, threats, catastrophes, bunker_features, action_cards, raids RESTART IDENTITY CASCADE")


puts "Создание профессий (расширенный список)..."
professions = [
  # --- Tier S (Критически важны: медицина, еда, энергия) ---
  { name: 'Хирург', tier: 'S', tags: 'medical, surgery', weight: 4, description: 'Способен проводить операции в полевых условиях.' },
  { name: 'Вирусолог', tier: 'S', tags: 'medical, science', weight: 4, description: 'Единственный, кто может создать вакцину от вируса.' },
  { name: 'Фермер', tier: 'S', tags: 'food, agriculture', weight: 3, description: 'Обеспечит бункер возобновляемой едой.' },
  { name: 'Инженер', tier: 'S', tags: 'technical, repair', weight: 3, description: 'Сможет поддерживать работу систем жизнеобеспечения.' },
  { name: 'Электрик', tier: 'S', tags: 'energy, repair', weight: 3, description: 'Сможет починить генератор и провести свет.' },
  { name: 'Химик', tier: 'S', tags: 'science, chemical', weight: 3, description: 'Умеет синтезировать лекарства и топливо.' },

  # --- Tier A (Очень полезны: безопасность, ремонт, прикладные навыки) ---
  { name: 'Военный', tier: 'A', tags: 'security, weapons', weight: 2, description: 'Дисциплинирован и умеет защищать группу.' },
  { name: 'Пожарный', tier: 'A', tags: 'security, rescue', weight: 2, description: 'Опыт спасения людей из экстремальных ситуаций.' },
  { name: 'Медсестра', tier: 'A', tags: 'medical', weight: 2, description: 'Первая помощь и уход за больными.' },
  { name: 'Стоматолог', tier: 'A', tags: 'medical, dental', weight: 2, description: 'Зубная боль в бункере — это приговор без него.' },
  { name: 'Автомеханик', tier: 'A', tags: 'technical, repair', weight: 2, description: 'Сможет починить любую технику и механизмы.' },
  { name: 'Лесник', tier: 'A', tags: 'survival, food', weight: 2, description: 'Знает все о выживании и съедобных растениях.' },
  { name: 'Физик', tier: 'A', tags: 'science, energy', weight: 2, description: 'Разбирается в радиации и фундаментальных процессах.' },
  { name: 'Робототехник', tier: 'A', tags: 'technical, robotic', weight: 2, description: 'Сможет автоматизировать процессы в бункере.' },
  { name: 'Повар', tier: 'A', tags: 'food, social', weight: 2, description: 'Сэкономит продукты, готовя питательно и вкусно.' },

  # --- Tier B (Полезны, но специфичны) ---
  { name: 'Полицейский', tier: 'B', tags: 'security, social', weight: 1, description: 'Поддержание порядка и разрешение конфликтов.' },
  { name: 'Спецагент', tier: 'B', tags: 'security, stealth', weight: 1, description: 'Навыки разведки и скрытых операций.' },
  { name: 'Психолог', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Следит, чтобы группа не сошла с ума в изоляции.' },
  { name: 'Хакер', tier: 'B', tags: 'technical, software', weight: 1, description: 'Сможет взломать внешние системы или архивы.' },
  { name: 'Строитель', tier: 'B', tags: 'technical, building', weight: 1, description: 'Навыки укрепления убежища.' },
  { name: 'Эколог', tier: 'B', tags: 'science, nature', weight: 1, description: 'Поможет понять, когда снаружи станет безопасно.' },
  { name: 'Знахарь', tier: 'B', tags: 'medical, herbal', weight: 1, description: 'Лечит травами, когда закончатся таблетки.' },
  { name: 'Детектив', tier: 'B', tags: 'security, logic', weight: 1, description: 'Найдет крысу в коллективе.' },

  # --- Tier C (Малополезны или спорны в условиях выживания) ---
  { name: 'Домохозяйка', tier: 'C', tags: 'social, household', weight: 0, description: 'Умеет создавать уют и организовывать быт.' },
  { name: 'Разнорабочий', tier: 'C', tags: 'physical', weight: 0, description: 'Просто крепкие руки для любой работы.' },
  { name: 'Программист', tier: 'C', tags: 'technical, software', weight: 0, description: 'Полезен, если в бункере есть работающие серверы.' },
  { name: 'Переводчик', tier: 'C', tags: 'social, language', weight: 0, description: 'Поможет, если встретите иностранцев.' },
  { name: 'Адвокат', tier: 'C', tags: 'social, law', weight: 0, description: 'Поможет составить внутренний кодекс бункера.' },
  { name: 'Летчик', tier: 'C', tags: 'transport', weight: 0, description: 'Полезен, если найдете вертолет.' },
  { name: 'Историк', tier: 'C', tags: 'social, history', weight: -1, description: 'Хранитель знаний прошлого.' },
  { name: 'Журналист', tier: 'C', tags: 'social, info', weight: -1, description: 'Будет вести хроники нового мира.' },
  { name: 'Дизайнер', tier: 'C', tags: 'art', weight: -1, description: 'Сделает стены бункера менее депрессивными.' },
  { name: 'Модель', tier: 'C', tags: 'appearance', weight: -1, description: 'Красивый человек, но без прикладных навыков.' },
  { name: 'Продавец', tier: 'C', tags: 'social, trade', weight: -1, description: 'Навыки торговли, если будет с кем торговать.' },
  { name: 'Писатель', tier: 'C', tags: 'art, social', weight: -1, description: 'Напишет новую Библию для выживших.' },
  { name: 'Сексолог', tier: 'C', tags: 'social, health', weight: -1, description: 'Разберется в тонких вопросах отношений.' },
  { name: 'Тату-мастер', tier: 'C', tags: 'art', weight: -1, description: 'Сделает отличительные знаки вашей группе.' },
  { name: 'Маркетолог', tier: 'C', tags: 'social', weight: -1, description: 'Умеет «продавать» идеи группе.' },
  { name: 'Этнограф', tier: 'C', tags: 'science, social', weight: -1, description: 'Изучает культуру, которая только что погибла.' },
  { name: 'Археолог', tier: 'C', tags: 'science, history', weight: -1, description: 'Привык копаться в руинах прошлого.' },

  # --- Tier "Опасные или бесполезные" (Отрицательный вес) ---
  { name: 'Гомеопат', tier: 'C', tags: 'pseudo_science', weight: -2, description: 'Предлагает лечить радиацию заряженной водой.' },
  { name: 'Коуч', tier: 'C', tags: 'social', weight: -2, description: 'Будет мотивировать вас выживать, пока вы умираете.' },
  { name: 'Папарацци', tier: 'C', tags: 'info, stealth', weight: -2, description: 'Привык следить за другими и сплетничать.' },
  { name: 'Грабитель', tier: 'C', tags: 'criminal, stealth', weight: -2, description: 'Опасный элемент, но умеет вскрывать замки.' },
  { name: 'Браконьер', tier: 'C ', tags: 'criminal, hunting', weight: -1, description: 'Умеет убивать животных, но плевать хотел на законы.' },
  { name: 'Видеоинженер', tier: 'C', tags: 'technical, media', weight: -1, description: 'Сможет настроить видеонаблюдение.' },
  { name: 'Судья', tier: 'C', tags: 'social, law', weight: -1, description: 'Привык распоряжаться судьбами, но здесь нет законов.' },
  { name: 'Философ', tier: 'C', tags: 'social, thought', weight: -2, description: 'Будет рассуждать о смысле смерти, когда нужно копать.' },
  { name: 'Экстрасенс', tier: 'C', tags: 'pseudo_science', weight: -2, description: 'Видит ауру бункера, но не видит утечку газа.' },
  { name: 'Экскурсовод', tier: 'C', tags: 'social', weight: -1, description: 'Расскажет, как красиво было в мире до апокалипсиса.' }
]

professions.each { |p| Card.create!(**p, category: 'profession') }

puts "Добавление новых профессий в справочник..."

new_professions = [
  # --- Tier S (Критически важны) ---
  { name: 'Генетик', tier: 'S', tags: 'medical, science, reproduction', weight: 4, description: 'Специалист по геному. Поможет избежать мутаций и решить проблемы бесплодия.' },
  { name: 'Агроном', tier: 'S', tags: 'food, agriculture, science', weight: 3, description: 'Знает, как заставить растения расти быстрее и сопротивляться болезням.' },
  { name: 'Архитектор', tier: 'S', tags: 'technical, building', weight: 3, description: 'Проектировщик сложных систем. Знает, как расширить бункер и укрепить своды.' },
  { name: 'Геолог', tier: 'S', tags: 'science, exploration, water', weight: 3, description: 'Найдет источники воды и полезные ископаемые в окрестностях.' },
  { name: 'Специалист по связи', tier: 'S', tags: 'technical, communication', weight: 3, description: 'Сможет настроить дальнюю радиосвязь и перехватить чужие сигналы.' },

  # --- Tier A (Очень полезны) ---
  { name: 'Психиатр', tier: 'A', tags: 'medical, mental_health', weight: 2, description: 'В отличие от психолога, может проводить медикаментозное лечение расстройств.' },
  { name: 'Охотник', tier: 'A', tags: 'food, security, tracking', weight: 2, description: 'Мастер выслеживания и добычи дичи. Опытен в обращении с оружием.' },
  { name: 'Ядерный физик', tier: 'A', tags: 'science, energy, radiation', weight: 2, description: 'Незаменим в мире после ядерного удара. Умеет работать с реакторами.' },
  { name: 'Фармацевт', tier: 'A', tags: 'medical, chemical', weight: 2, description: 'Сможет изготовить лекарства из подручных средств и химии.' },
  { name: 'Кинолог', tier: 'A', tags: 'security, dogs, social', weight: 2, description: 'Умеет дрессировать собак для охраны и поиска ресурсов.' },

  # --- Tier B (Специфические) ---
  { name: 'Телохранитель', tier: 'B', tags: 'security, physical', weight: 1, description: 'Обучен защищать VIP-персон. Отличная реакция и физическая подготовка.' },
  { name: 'Священник', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Поднимет дух верующим, примирит враждующих и выслушает исповедь.' },
  { name: 'Мясник', tier: 'B', tags: 'food, physical', weight: 1, description: 'Мастер разделки туш. Умеет долго хранить мясо без холодильника.' },
  { name: 'Электромеханик', tier: 'B', tags: 'technical, repair, energy', weight: 1, description: 'Специалист по лифтам, вентиляторам и другим сложным машинам.' },
  { name: 'Инструктор по выживанию', tier: 'B', tags: 'survival, exploration', weight: 1, description: 'Знает сотни способов развести костер и построить укрытие из веток.' },

  # --- Tier C (Спорные/Специфические) ---
  { name: 'Библиотекарь', tier: 'C', tags: 'social, history, info', weight: 0, description: 'Хранитель бумажных знаний. Поможет найти нужную информацию в архивах.' },
  { name: 'Гробовщик', tier: 'C', tags: 'physical, health', weight: 0, description: 'Знает всё о санитарных нормах при захоронении. Привык к мрачной работе.' },
  { name: 'Йога-инструктор', tier: 'C', tags: 'health, physical, social', weight: 0, description: 'Поможет группе сохранять гибкость тела и спокойствие ума.' },
  { name: 'Скульптор', tier: 'C', tags: 'art, physical', weight: -1, description: 'Умеет работать с камнем, глиной и металлом. Сделает бункер красивее.' },
  { name: 'Страховой агент', tier: 'C', tags: 'social, law', weight: -1, description: 'Мастер убеждения. Умеет оценивать риски (хотя здесь это вряд ли поможет).' },
  { name: 'Блогер', tier: 'C', tags: 'social, info, media', weight: -1, description: 'Умеет привлекать внимание и работать с аудиторией. Бесполезен без интернета.' },
  { name: 'Таксидермист', tier: 'C', tags: 'art, science', weight: -1, description: 'Умеет делать чучела. В условиях голода его навыки работы с тушами могут пригодиться.' },
  { name: 'Каскадер', tier: 'C', tags: 'physical, risk', weight: 0, description: 'Привык рисковать жизнью и выполнять опасные трюки. Полезен в рейдах.' },
  { name: 'Арбитражный управляющий', tier: 'C', tags: 'social, law, logic', weight: -1, description: 'Специалист по банкротствам. Знает, как распределить остатки ресурсов.' },
  { name: 'Астролог', tier: 'C', tags: 'social, pseudo_science', weight: -2, description: 'Предскажет судьбу по звездам. Правда, звезд из-за пыли в небе не видно.' }
]

new_professions.each { |p| Card.create!(**p, category: 'profession') }

puts "Профессии обновлены! Всего в базе: #{Card.where(category: 'profession').count}"

puts "Создание здоровья (расширенный список)..."
healths = [
  # --- Tier S (Отличное или скрытое состояние) ---
  { name: 'Идеально здоров', tier: 'S', tags: 'healthy', weight: 2, description: 'Никаких жалоб, идеальные показатели.', is_curable: true },
  { name: 'Не обследовался', tier: 'S', tags: 'unknown', weight: 0, description: 'Чувствует себя нормально, но кто знает, что внутри...', is_curable: true },
  { name: 'Иммунитет к вирусам', tier: 'S', tags: 'healthy, vital', weight: 3, description: 'Его организм вырабатывает антитела к любым внешним угрозам.', is_curable: false },

  # --- Tier A (Мелкие странности или легкие дефекты) ---
  { name: 'Повышенная волосатость', tier: 'A', tags: 'physical, cosmetic', weight: 0, description: 'Густая шерсть по всему телу. Зимой даже плюс.', is_curable: false },
  { name: 'Потеря обоняния', tier: 'A', tags: 'sensory', weight: 0, description: 'Не чувствует запахов. Полезно при очистке туалетов в бункере.', is_curable: true },
  { name: 'Хвост', tier: 'A', tags: 'physical, genetic', weight: -1, description: 'Небольшой рудиментарный отросток. Слегка мешает сидеть.', is_curable: false },
  { name: 'Кофейная зависимость', tier: 'A', tags: 'addiction', weight: -1, description: 'Без чашки кофе по утрам становится очень раздражительным.', is_curable: true },
  { name: 'Дальтонизм', tier: 'A', tags: 'sensory', weight: 0, description: 'Не различает некоторые цвета. Проблема при починке сложной электроники.', is_curable: false },
  { name: 'Хронический храп', tier: 'A', tags: 'physical, social', weight: -1, description: 'Издает звуки мощностью в 80 децибел. Мешает спать всему бункеру.', is_curable: true },

  # --- Tier B (Зависимости и управляемые проблемы) ---
  { name: 'Заика', tier: 'B', tags: 'physical, social', weight: -1, description: 'Трудно говорить в стрессовых ситуациях.', is_curable: true },
  { name: 'Фригидность / Импотенция', tier: 'B', tags: 'reproduction, physical', weight: -1, description: 'Проблемы в интимной сфере.', is_curable: true },
  { name: 'Мигрень', tier: 'B', tags: 'physical, pain', weight: -1, description: 'Периодические приступы сильнейшей головной боли.', is_curable: true },
  { name: 'Понос', tier: 'B', tags: 'physical, infection', weight: -1, description: 'Кишечное расстройство. Требует много воды и бумаги.', is_curable: true },
  { name: 'Клептомания', tier: 'B', tags: 'mental, addiction', weight: -2, description: 'Непреодолимое желание прибрать к рукам чужие вещи.', is_curable: true },
  { name: 'Игровая зависимость', tier: 'B', tags: 'mental, addiction', weight: -1, description: 'Готов спорить и играть на что угодно.', is_curable: true },
  { name: 'Паразиты', tier: 'B', tags: 'physical, infection', weight: -1, description: 'Внутренние «сожители». Постоянный голод и боли в животе.', is_curable: true },
  { name: 'Цинга', tier: 'B', tags: 'physical, infection', weight: -1, description: 'Острая нехватка витаминов. Кровоточат десны, выпадают зубы.', is_curable: true },

  # --- Tier C (Серьезные физические травмы и инвалидность) ---
  { name: 'Бесплодие', tier: 'C', tags: 'reproduction', weight: -2, description: 'Не может иметь детей. Удар по будущему популяции.', is_curable: false },
  { name: 'Слепой', tier: 'C', tags: 'sensory, disability', weight: -4, description: 'Полная темнота. Нуждается в постоянной опеке.', is_curable: false },
  { name: 'Глухой', tier: 'C', tags: 'sensory, disability', weight: -3, description: 'Не слышит звуков. Нужен сурдоперевод или переписка.', is_curable: false },
  { name: 'Нет ноги', tier: 'C', tags: 'physical, disability', weight: -3, description: 'Передвигается на костылях или протезе.', is_curable: false },
  { name: 'Нет руки', tier: 'C', tags: 'physical, disability', weight: -3, description: 'Сложно выполнять любую физическую работу.', is_curable: false },
  { name: 'Тремор рук', tier: 'C', tags: 'physical, neurological', weight: -2, description: 'Руки постоянно дрожат. Не может делать точную работу.', is_curable: true },
  { name: 'Карлик', tier: 'C', tags: 'physical, genetic', weight: -1, description: 'Очень низкий рост. Протискивается там, где другие не могут.', is_curable: false },
  { name: 'Гигантизм', tier: 'C', tags: 'physical, genetic', weight: -2, description: 'Непропорционально большие конечности. Требует больше еды и места.', is_curable: false },
  { name: 'Лучевая болезнь', tier: 'C', tags: 'physical, radiation', weight: -3, description: 'Последствия облучения. Тошнота, слабость, внутренние кровотечения.', is_curable: true },
  { name: 'Эпилепсия', tier: 'C', tags: 'physical, neurological', weight: -2, description: 'Возможны внезапные приступы. Опасен в рейдах.', is_curable: true },
  { name: 'Порок сердца', tier: 'C', tags: 'physical, vital', weight: -3, description: 'Любая сильная нагрузка может стать последней.', is_curable: false },
  { name: 'Гемофилия', tier: 'C', tags: 'physical, vital', weight: -3, description: 'Несвертываемость крови. Любая царапина — смертельна.', is_curable: false },

  # --- Tier C (Ментальные расстройства) ---
  { name: 'Депрессия', tier: 'C', tags: 'mental', weight: -2, description: 'Постоянная апатия и отсутствие желания бороться за жизнь.', is_curable: true },
  { name: 'Галлюцинации', tier: 'C', tags: 'mental', weight: -3, description: 'Видит и слышит то, чего нет на самом деле.', is_curable: true },
  { name: 'Раздвоение личности', tier: 'C', tags: 'mental', weight: -3, description: 'Внутри живут два разных человека с разными именами.', is_curable: true },
  { name: 'Мания преследования', tier: 'C', tags: 'mental', weight: -2, description: 'Уверен, что другие игроки хотят его убить.', is_curable: true },
  { name: 'Лунатизм', tier: 'C', tags: 'mental', weight: -2, description: 'Ходит и разговаривает во сне. Может случайно выйти из бункера.', is_curable: true },
  { name: 'Склероз', tier: 'C', tags: 'mental, memory', weight: -2, description: 'Забывает события, имена и где оставил вещи.', is_curable: true },
  { name: 'Суицидальные мысли', tier: 'C', tags: 'mental', weight: -3, description: 'Опасен для самого себя, нужен постоянный присмотр.', is_curable: true },
  { name: 'Сексуальная озабоченность', tier: 'C', tags: 'mental, social', weight: -2, description: 'Постоянно донимает окружающих непристойностями.', is_curable: true },
  { name: 'Синдром Туретта', tier: 'C', tags: 'neurological, social', weight: -2, description: 'Непроизвольные выкрики (иногда бранные). Мешает скрытности.', is_curable: true },

  # --- Тяжелые зависимости ---
  { name: 'Алкоголизм', tier: 'C', tags: 'addiction, physical', weight: -2, description: 'При отсутствии спиртного начинается тяжелая ломка.', is_curable: true },
  { name: 'Наркомания', tier: 'C', tags: 'addiction, physical', weight: -3, description: 'Нуждается в регулярной дозе сильных препаратов.', is_curable: true }
]

healths.each { |h| Card.create!(**h, category: 'health') }

puts "Справочник здоровья обновлен! Всего записей: #{Card.where(category: 'health').count}"

luggages = [
  # --- Tier S (Критически важны: медицина, энергия, выживание) ---
  { name: 'Инкубатор с яйцами', tier: 'S', tags: 'food, farming, birds', weight: 4, description: 'Шанс завести собственную птицеферму внутри бункера.' },
  { name: 'Саженцы фруктовых деревьев', tier: 'S', tags: 'food, farming', weight: 4, description: 'Основа для будущего сада. Требуют ухода и места.' },
  { name: 'Переносная электростанция', tier: 'S', tags: 'energy, technical', weight: 4, description: 'Заряжается от солнца или движения. Даст свет и ток.' },
  { name: 'Промышленный фильтр для воды', tier: 'S', tags: 'water, technical', weight: 4, description: 'Способен очистить даже самую грязную воду. Прямой контр-пик угрозе отравления.' },
  { name: 'Антибиотики и обезболивающее', tier: 'S', tags: 'medical, healing', weight: 3, description: 'Запас сильных лекарств на экстренный случай.' },
  { name: 'Чемоданчик фельдшера', tier: 'S', tags: 'medical, healing', weight: 3, description: 'Профессиональный набор инструментов для первой помощи.' },
  { name: 'Снайперская винтовка', tier: 'S', tags: 'security, weapon', weight: 3, description: 'Позволит контролировать периметр на дальних дистанциях.' },
  { name: 'Современный хирургический набор', tier: 'S', tags: 'medical, surgery', weight: 3, description: 'Скальпели, зажимы, шовный материал. Мечта любого хирурга.' },

  # --- Tier A (Очень полезны: инструменты, защита, наука) ---
  { name: 'Мешок зерна', tier: 'A', tags: 'food, farming', weight: 2, description: 'Можно съесть сейчас или посадить для получения урожая.' },
  { name: 'Мешок картошки', tier: 'A', tags: 'food, farming', weight: 2, description: 'Стратегический запас углеводов и семенной фонд.' },
  { name: 'Инструменты электрика', tier: 'A', tags: 'technical, energy, repair', weight: 2, description: 'Мультиметр, паяльник и кусачки. Незаменимы при поломках.' },
  { name: 'Прибор ночного видения', tier: 'A', tags: 'security, exploration', weight: 2, description: 'Дает преимущество в темноте за пределами бункера.' },
  { name: 'Пистолет', tier: 'A', tags: 'security, weapon', weight: 2, description: 'Компактное средство самообороны.' },
  { name: 'Дефибриллятор', tier: 'A', tags: 'medical, energy', weight: 2, description: 'Может спасти жизнь при остановке сердца. Нужен ток.' },
  { name: 'Звуковая отвертка', tier: 'A', tags: 'technical, repair', weight: 2, description: 'Странный высокотехнологичный гаджет. Чинит почти всё.' },
  { name: 'Счетчик Гейгера', tier: 'A', tags: 'science, radiation', weight: 2, description: 'Позволяет вовремя заметить радиационную опасность.' },
  { name: 'Армейский противогаз (5 фильтров)', tier: 'A', tags: 'security, survival, radiation', weight: 2, description: 'Защита от пыли, спор и химических атак.' },

  # --- Tier B (Полезные инструменты и навыки) ---
  { name: 'Лук и стрелы', tier: 'B', tags: 'security, weapon, hunting', weight: 1, description: 'Бесшумное оружие. Стрелы можно изготовить самому.' },
  { name: 'Компас и карта окрестностей', tier: 'B', tags: 'exploration, survival', weight: 1, description: 'Помогут не заблудиться при вылазках за ресурсами.' },
  { name: 'Набор отмычек', tier: 'B', tags: 'stealth, survival', weight: 1, description: 'Позволит вскрыть заброшенные склады и аптеки.' },
  { name: 'Капканы и набор ядов', tier: 'B', tags: 'hunting, security', weight: 1, description: 'Эффективно для добычи еды и защиты от незваных гостей.' },
  { name: 'Ножи для метания', tier: 'B', tags: 'security, weapon', weight: 1, description: 'Требуют мастерства, но не шумят и не требуют патронов.' },
  { name: 'Столярные инструменты', tier: 'B', tags: 'technical, building', weight: 1, description: 'Пилы, стамески, рубанки. Полезны для обустройства быта.' },
  { name: 'Ноутбук и платы Arduino', tier: 'B', tags: 'technical, software', weight: 1, description: 'Для создания простых систем автоматизации или связи.' },
  { name: 'Энциклопедия грибника', tier: 'B', tags: 'food, survival', weight: 1, description: 'Поможет отличить сытный обед от смертельного ужина.' },
  { name: 'Ящик водки', tier: 'B', tags: 'alcohol, medical, social', weight: 1, description: 'Универсальная валюта, антисептик и средство для снятия стресса.' },
  { name: 'Наручники', tier: 'B', tags: 'security', weight: 1, description: 'Помогут усмирить буйного члена группы или пленника.' },

  # --- Tier C (Малополезные, социальные или "балласт") ---
  { name: 'Гитара', tier: 'C', tags: 'social, mental', weight: 0, description: 'Развлечение и поднятие духа в депрессивном бункере.' },
  { name: 'Настольные игры', tier: 'C', tags: 'social, mental', weight: 0, description: 'Помогут не сойти с ума от скуки в течение 5 лет.' },
  { name: 'Книги Айзека Азимова', tier: 'C', tags: 'mental, education', weight: 0, description: 'Классика научной фантастики. Напоминание о былом величии.' },
  { name: '3 слитка золота', tier: 'C', tags: 'wealth, ballast', weight: -1, description: 'Красиво блестят, но в новом мире на них ничего не купишь.' },
  { name: 'Спиритическая доска', tier: 'C', tags: 'strange, mental', weight: -1, description: 'Для общения с духами тех, кто не попал в бункер.' },
  { name: 'Кукла вуду', tier: 'C', tags: 'strange', weight: -1, description: 'Попытка контролировать врагов магией. Вряд ли сработает.' },
  { name: 'Миллион долларов', tier: 'C', tags: 'wealth, ballast', weight: -2, description: 'Куча крашеной бумаги. Отлично подходит для растопки печи.' },
  { name: 'Надувная кукла', tier: 'C', tags: 'strange, social', weight: -1, description: 'Очень странный предмет для выживания. Вызывает вопросы.' },
  { name: 'Шапочка из фольги', tier: 'C', tags: 'joke, mental', weight: -2, description: 'Защищает от рептилоидов и 5G. По крайней мере, вы в это верите.' },
  { name: 'Коробка редких специй', tier: 'C', tags: 'food, social', weight: 0, description: 'Сделает даже самую пресную гречку деликатесом. Поможет повару.' },
  { name: 'Коллекция эротических журналов', tier: 'C', tags: 'social, mental', weight: -1, description: 'Сомнительная ценность для выживания, но предмет для обмена.' }
]

luggages.each { |l| Card.create!(**l, category: 'luggage') }

puts "Багаж обновлен! Всего предметов: #{Card.where(category: 'luggage').count}"

puts "Создание фобий (полный список 30+)..."
phobias = [
  # --- Tier S (Кремень / Высокая стрессоустойчивость) ---
  { name: 'Нет фобий', tier: 'S', tags: 'brave, mental', weight: 1, description: 'Психика непоколебима. Способен сохранять рассудок в любой ситуации.', is_curable: true },
  { name: 'Крепкая психика', tier: 'S', tags: 'brave, mental', weight: 1, description: 'Стрессоустойчивость выше среднего. Редко поддается панике.', is_curable: true },
  { name: 'Стальные нервы', tier: 'S', tags: 'brave, mental', weight: 1, description: 'Хладнокровие — его второе имя. Полезен в экстремальных вылазках.', is_curable: true },
  { name: 'Оптимист', tier: 'S', tags: 'brave, mental, social', weight: 1, description: 'Всегда видит свет в конце тоннеля. Моральная опора группы.', is_curable: true },

  # --- Tier A (Легкие или специфические страхи) ---
  { name: 'Арахнофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь пауков. Будет кричать при виде любого насекомого.', is_curable: true },
  { name: 'Айхмофобия', tier: 'A', tags: 'panic, mental, sharp', weight: -1, description: 'Боязнь острых предметов. Не сможет пользоваться ножом или скальпелем.', is_curable: true },
  { name: 'Кинофобия', tier: 'A', tags: 'panic, mental, dogs', weight: -1, description: 'Боязнь собак. Проблема, если в багаже у кого-то есть пес.', is_curable: true },
  { name: 'Айлурофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь кошек. Нервничает, если рядом пушистый зверь (или Котопокалипсис).', is_curable: true },
  { name: 'Спектрофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь зеркал. Будет завешивать все отражающие поверхности.', is_curable: true },
  { name: 'Акустикофобия', tier: 'A', tags: 'panic, mental, noise', weight: -1, description: 'Боязнь громких звуков. Взрывы или шум вызывают истерику.', is_curable: true },
  { name: 'Герпетофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь рептилий. Плохо сочетается с катастрофой "Динозавры".', is_curable: true },
  { name: 'Ботанофобия', tier: 'A', tags: 'panic, mental, nature', weight: -1, description: 'Боязнь растений. Не сможет работать в оранжерее или саду.', is_curable: true },

  # --- Tier B (Социальные и функциональные страхи) ---
  { name: 'Петтофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь пукнуть при людях. Постоянное дикое напряжение в животе.', is_curable: true },
  { name: 'Децидофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь принимать решения. Никогда не сможет быть лидером.', is_curable: true },
  { name: 'Охлофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь толпы. Жить в тесном бункере с людьми — мучение.', is_curable: true },
  { name: 'Андрофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь мужчин. Опасается половины населения бункера.', is_curable: true },
  { name: 'Гинофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь женщин. Проблемы с общением и репродукцией.', is_curable: true },
  { name: 'Педофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь детей. Не захочет участвовать в возрождении популяции.', is_curable: true },
  { name: 'Эротофобия', tier: 'B', tags: 'sexual, mental', weight: -1, description: 'Боязнь секса и наготы. Мешает созданию пар.', is_curable: true },
  { name: 'Аблютофобия', tier: 'B', tags: 'hygiene, mental', weight: -2, description: 'Боязнь мытья. Станет источником вони и инфекций.', is_curable: true },
  { name: 'Ксенофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь чужаков. Будет первым, кто предложит стрелять при "Нападении извне".', is_curable: true },
  { name: 'Глоссофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь публичных выступлений. Ему сложно защищать себя на советах.', is_curable: true },

  # --- Tier C (Тяжелые дебаффы для выживания) ---
  { name: 'Клаустрофобия', tier: 'C', tags: 'panic, mental, confined', weight: -3, description: 'Боязнь замкнутых пространств. Постоянные попытки выбежать наружу.', is_curable: true },
  { name: 'Никтофобия', tier: 'C', tags: 'panic, mental, dark', weight: -2, description: 'Панический страх темноты. Требует, чтобы свет горел 24/7.', is_curable: true },
  { name: 'Агорафобия', tier: 'C', tags: 'panic, mental, open_space', weight: -2, description: 'Боязнь открытых пространств. Откажется выходить из бункера на рейды.', is_curable: true },
  { name: 'Мисофобия', tier: 'C', tags: 'panic, mental, germs', weight: -2, description: 'Боязнь микробов. Изведет все запасы антисептика и воды.', is_curable: true },
  { name: 'Генофобия', tier: 'C', tags: 'panic, mental, blood', weight: -2, description: 'Боязнь крови. Падает в обморок при любой травме соседа.', is_curable: true },
  { name: 'Аквафобия', tier: 'C', tags: 'panic, mental, water', weight: -2, description: 'Боязнь утонуть. Боится даже глубоких луж и баков с водой.', is_curable: true },
  { name: 'Сомнифобия', tier: 'C', tags: 'panic, mental, sleep', weight: -3, description: 'Боязнь спать. Будет страдать от галлюцинаций из-за недосыпа.', is_curable: true },
  { name: 'Технофобия', tier: 'C', tags: 'panic, mental, tech', weight: -2, description: 'Боязнь сложной техники. Может сломать компьютер бункера со страху.', is_curable: true },
  { name: 'Ректофобия', tier: 'C', tags: 'physical, mental', weight: -2, description: 'Боязнь процесса дефекации. Серьезные проблемы со здоровьем через неделю.', is_curable: true },
  { name: 'Хронофобия', tier: 'C', tags: 'mental, time', weight: -2, description: 'Боязнь течения времени. Сходит с ума от осознания лет в заточении.', is_curable: true },
  { name: 'Фазмофобия', tier: 'C', tags: 'panic, mental', weight: -1, description: 'Боязнь призраков. Будет видеть привидений в каждом углу.', is_curable: true },
  { name: 'Танатофобия', tier: 'C', tags: 'panic, mental', weight: -3, description: 'Боязнь смерти. Станет самым трусливым членом команды.', is_curable: true },
  { name: 'Фобофобия', tier: 'C', tags: 'mental', weight: -2, description: 'Страх самого чувства страха. Зацикленная паническая атака.', is_curable: true },
  { name: 'Акрофобия', tier: 'C', tags: 'panic, mental, height', weight: -1, description: 'Боязнь высоты. Бесполезен на смотровых вышках.', is_curable: true },
  { name: 'Иатрофобия', tier: 'C', tags: 'panic, mental, medical', weight: -2, description: 'Боязнь врачей. Не подпустит к себе медика даже при ранении.', is_curable: true },
  { name: 'Сцелерофобия', tier: 'C', tags: 'panic, mental, criminal', weight: -2, description: 'Боязнь плохих людей/грабителей. Подозревает всех в злом умысле.', is_curable: true },
  { name: 'Автофобия', tier: 'C', tags: 'panic, mental, isolation', weight: -2, description: 'Боязнь одиночества. Начнет истерику, если оставить его на посту одного.', is_curable: true },
  { name: 'Механофобия', tier: 'C', tags: 'panic, mental, tech', weight: -2, description: 'Боязнь механизмов. Впадает в ступор при виде работающего двигателя.', is_curable: true },
  { name: 'Пирофобия', tier: 'C', tags: 'panic, mental, fire', weight: -2, description: 'Панический страх огня. Не сможет даже зажечь спичку или готовить еду.', is_curable: true }
]

phobias.each { |ph| Card.create!(**ph, category: 'phobia') }

puts "Справочник фобий готов! Всего записей: #{Card.where(category: 'phobia').count}"

puts "Создание хобби (расширенный список)..."
puts "Обновление справочника хобби (50 позиций)..."

hobbies = [
  # --- Tier S (Критически полезные навыки для выживания и созидания) ---
  { name: 'Гидропоника', tier: 'S', tags: 'food, agriculture, science', weight: 3, description: 'Умеет выращивать растения без почвы, на питательных растворах.' },
  { name: 'Любительская радиосвязь', tier: 'S', tags: 'technical, communication', weight: 3, description: 'Сможет собрать рацию из мусора и выйти на связь с другими выжившими.' },
  { name: 'Охота и рыбалка', tier: 'S', tags: 'food, survival, weapon', weight: 3, description: 'Мастер добычи пропитания в дикой природе.' },
  { name: 'Робототехника', tier: 'S', tags: 'technical, repair', weight: 3, description: 'Собирает дронов и автоматизирует системы защиты.' },
  { name: 'Боевые искусства', tier: 'S', tags: 'security, physical', weight: 2, description: 'Черный пояс. Может нейтрализовать противника без оружия.' },
  { name: 'Кузнечное дело', tier: 'S', tags: 'technical, crafting, physical', weight: 3, description: 'Умеет работать с металлом, ковать инструменты и укреплять двери.' },
  { name: 'Пчеловодство', tier: 'S', tags: 'food, nature', weight: 2, description: 'Знает, как развести пасеку. Мед — это и еда, и лекарство.' },

  # --- Tier A (Прикладные, медицинские и инженерные навыки) ---
  { name: 'Холодное оружие', tier: 'A', tags: 'security, weapon', weight: 2, description: 'Коллекционирует и мастерски владеет ножами и топорами.' },
  { name: 'Дачник', tier: 'A', tags: 'food, agriculture', weight: 2, description: 'Знает, как выжать максимум урожая из шести соток.' },
  { name: 'Пиротехника', tier: 'A', tags: 'technical, explosive', weight: 2, description: 'Умеет создавать взрывчатку и сигнальные огни из бытовой химии.' },
  { name: 'Массаж и акупунктура', tier: 'A', tags: 'medical, health', weight: 1, description: 'Снимает боли и лечит зажимы без лекарств.' },
  { name: 'Пивоварение', tier: 'A', tags: 'food, social, medical', weight: 1, description: 'Спирт — лучший антисептик и валюта апокалипсиса.' },
  { name: 'Паркур', tier: 'A', tags: 'physical, exploration', weight: 1, description: 'Мастер перемещения по руинам и препятствиям.' },
  { name: 'Шитье и кройка', tier: 'A', tags: 'crafting, social', weight: 2, description: 'Сможет чинить одежду и шить спецснаряжение из тентов.' },
  { name: 'Консервирование', tier: 'A', tags: 'food, health', weight: 2, description: 'Мастер заготовок. Может сохранить продукты съедобными на годы.' },
  { name: 'Слесарное дело', tier: 'A', tags: 'technical, repair', weight: 2, description: 'Разбирается в замках, трубах и простых механизмах.' },

  # --- Tier B (Социальные, интеллектуальные и умеренно полезные) ---
  { name: 'ЗОЖ', tier: 'B', tags: 'health, physical', weight: 1, description: 'Никогда не болеет и мотивирует всех делать зарядку.' },
  { name: 'Нетрадиционная медицина', tier: 'B', tags: 'medical, strange', weight: 0, description: 'Лечит прикладыванием подорожника и энергией космоса.' },
  { name: 'Разговоры по душам', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Прирожденный слушатель, может успокоить любого в истерике.' },
  { name: 'Медитация', tier: 'B', tags: 'mental, health', weight: 1, description: 'Сохраняет ледяное спокойствие даже когда все рушится.' },
  { name: 'Нетворкинг', tier: 'B', tags: 'social', weight: 1, description: 'Умеет договариваться и объединять даже враждующих людей.' },
  { name: 'Краеведение', tier: 'B', tags: 'exploration, history', weight: 1, description: 'Знает все тайные ходы и заброшенные склады в округе.' },
  { name: 'Настольные игры', tier: 'B', tags: 'social, mental', weight: 0, description: 'Знает правила сотен игр, не даст группе заскучать.' },
  { name: 'Спорт и танцы', tier: 'B', tags: 'physical, social', weight: 0, description: 'Хорошая координация и выносливость.' },
  { name: 'Йога', tier: 'B', tags: 'health, mental', weight: 1, description: 'Помогает поддерживать гибкость и психическое равновесие.' },
  { name: 'Сторителлинг', tier: 'B', tags: 'social, art', weight: 1, description: 'Мастер рассказывать истории. Единственное развлечение, когда нет света.' },
  { name: 'Карточные фокусы', tier: 'B', tags: 'social, stealth', weight: 0, description: 'Ловкость рук. Может развлечь группу или незаметно что-то украсть.' },

  # --- Tier C (Странные, бесполезные или пугающие) ---
  { name: 'ПК игры', tier: 'C', tags: 'useless', weight: -1, description: 'Помнит тактики в WoW, но не знает, как зажечь костер.' },
  { name: 'Кино и сериалы', tier: 'C', tags: 'useless', weight: -1, description: 'Знает цитаты на все случаи жизни, но бесполезен в быту.' },
  { name: 'Современное искусство', tier: 'C', tags: 'social, art', weight: -1, description: 'Видит глубокий смысл в ржавой трубе бункера.' },
  { name: 'Флудить в чатах', tier: 'C', tags: 'social, annoying', weight: -2, description: 'Одержим общением, даже если его никто не слушает.' },
  { name: 'Уфология и мистика', tier: 'C', tags: 'strange', weight: -1, description: 'Ждет спасения от инопланетян, а не от инженеров.' },
  { name: 'Алхимия', tier: 'C', tags: 'strange, science', weight: -1, description: 'Пытается превратить свинец в золото (пока безуспешно).' },
  { name: 'Грибы и гомеопатия', tier: 'C', tags: 'medical, strange', weight: -1, description: 'Разбирается в мухоморах и разведении воды.' },
  { name: 'Черная магия', tier: 'C', tags: 'strange, scary', weight: -2, description: 'Рисует пентаграммы на стенах и шепчет проклятия.' },
  { name: 'Вуайеризм', tier: 'C', tags: 'strange, criminal', weight: -2, description: 'Любит подглядывать за другими через вентиляцию.' },
  { name: 'Свинг-вечеринка', tier: 'C', tags: 'social, sexual', weight: -1, description: 'Сторонник очень свободных отношений в коллективе.' },
  { name: 'Стриптиз', tier: 'C', tags: 'physical, social', weight: -1, description: 'Умеет красиво раздеваться под музыку. Эффектно, но зачем?' },
  { name: 'Коллекционирование фантиков', tier: 'C', tags: 'useless', weight: -2, description: 'Тратит время на перебирание мусора. Абсолютно бесполезно.' },
  { name: 'Таксидермия', tier: 'C', tags: 'strange, crafting', weight: -1, description: 'Делает чучела животных. Жутковатое хобби для замкнутого пространства.' },
  { name: 'Троллинг в интернете', tier: 'C', tags: 'social, annoying', weight: -2, description: 'Привык выводить людей из себя. Продолжит это делать вживую.' },
  { name: 'Спиритизм', tier: 'C', tags: 'strange, mental', weight: -1, description: 'Пытается вызвать духов погибших. Пугает окружающих.' },
  { name: 'Гончарное дело', tier: 'C', tags: 'crafting', weight: 0, description: 'Умеет лепить горшки. Полезно, если в бункере есть печь и глина.' },
  { name: 'Поэзия', tier: 'C', tags: 'art, social', weight: -1, description: 'Пишет стихи о конце света. Нагоняет тоску.' },
  { name: 'Битбокс', tier: 'C', tags: 'social, noise', weight: -1, description: 'Имитирует звуки инструментов ртом. Постоянно шумит.' }
]

hobbies.each { |hb| Card.create!(**hb, category: 'hobby') }

puts "Справочник хобби готов! Всего записей: #{Card.where(category: 'hobby').count}"

puts "Создание фактов (расширенный список)..."
facts = [
  # --- Tier S (Критически полезные или уникальные знания) ---
  { name: 'Нобелевский лауреат по биоинженерии', tier: 'S', tags: 'science, medical', weight: 4, description: 'Гений мирового уровня. Может спасти человечество или создать лекарство.' },
  { name: 'Взломал базу данных ЦРУ', tier: 'S', tags: 'technical, security, info', weight: 3, description: 'Обладает доступом к секретным архивам и навыками кибервойны.' },
  { name: 'Строил подобные бункеры', tier: 'S', tags: 'technical, building', weight: 3, description: 'Знает все слабые места, скрытые вентиляционные шахты и сейфы убежища.' },
  { name: 'Знает лично президента', tier: 'S', tags: 'social, authority', weight: 2, description: 'Имеет связи на самом высоком уровне. Знает протоколы эвакуации правительства.' },
  { name: 'Телепат', tier: 'S', tags: 'strange, mental', weight: 3, description: 'Утверждает, что слышит мысли других. Группа никогда не будет знать, лжет он или нет.' },
  { name: 'Понимает язык животных', tier: 'S', tags: 'strange, nature', weight: 2, description: 'Может договориться с крысами в бункере или мутантами снаружи.' },
  { name: 'Запустил IT-стартап', tier: 'S', tags: 'social, technical', weight: 2, description: 'Обладает навыками управления ресурсами и системным мышлением.' },
  { name: 'Носитель антител', tier: 'S', tags: 'medical, vital', weight: 4, description: 'Его кровь — ключ к созданию вакцины от текущей катастрофы.' },
  { name: 'Знает код от секретного отсека', tier: 'S', tags: 'info, technical', weight: 3, description: 'В этом бункере есть запертая комната с припасами, код от которой есть только у него.' },

  # --- Tier A (Боевой опыт и выживание) ---
  { name: 'Вернулся из горячей точки', tier: 'A', tags: 'security, combat', weight: 2, description: 'Боевой опыт, умеет сохранять хладнокровие под обстрелом.' },
  { name: 'Вырос в семье лесника', tier: 'A', tags: 'nature, survival', weight: 2, description: 'С детства знает, как ориентироваться без карт и добывать воду из корней.' },
  { name: 'Выживал на необитаемом острове', tier: 'A', tags: 'survival', weight: 2, description: 'Опыт полной изоляции и строительства жилья из мусора.' },
  { name: 'Знает азбуку Морзе', tier: 'A', tags: 'communication, technical', weight: 1, description: 'Сможет передать сигнал SOS стуком по трубам или миганием фонаря.' },
  { name: 'Сделает алкоголь из чего угодно', tier: 'A', tags: 'food, alcohol, chemical', weight: 2, description: 'Мастер дистилляции. Обеспечит группу антисептиком и валютой.' },
  { name: 'Владеет 5 языками', tier: 'A', tags: 'social, language', weight: 1, description: 'Сможет договориться с любыми группами выживших или иностранными базами.' },
  { name: 'Мастер маскировки', tier: 'A', tags: 'stealth, security', weight: 1, description: 'Может сделать группу невидимой для угроз снаружи.' },

  # --- Tier B (Странности и социальные таланты) ---
  { name: 'Душа компании', tier: 'B', tags: 'social', weight: 2, description: 'Обладает гипнотической улыбкой. Легко гасит конфликты в коллективе.' },
  { name: 'Прошел 2-недельные курсы психолога', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Уверен, что может лечить людей. Иногда это даже помогает.' },
  { name: 'Обладатель уникального сопрано', tier: 'B', tags: 'art, social', weight: 0, description: 'Его пение — единственный способ не сойти с ума от тишины.' },
  { name: 'Победитель Паралимпийских игр', tier: 'B', tags: 'physical, survival', weight: 1, description: 'Железная воля и запредельная выносливость.' },
  { name: 'Читал все книги Лавкрафта', tier: 'B', tags: 'strange', weight: 0, description: 'Психически готов к встрече с самыми жуткими тварями апокалипсиса.' },
  { name: 'Продал почку', tier: 'B', tags: 'physical', weight: -1, description: 'Имеет опыт выживания после тяжелых операций, но здоровье подорвано.' },
  { name: 'Потомственный шаман', tier: 'B', tags: 'strange, mental_health', weight: 1, description: 'Умеет входить в транс и «предсказывать» погоду или угрозы.' },

  # --- Tier C (Опасные тайны и социальный балласт) ---
  { name: 'Маньяк-убийца', tier: 'C', tags: 'danger, criminal', weight: -4, description: 'Скрытая угроза. Велик шанс, что в бункере начнут пропадать люди.' },
  { name: 'Скрытый каннибал', tier: 'C', tags: 'danger, food', weight: -4, description: 'При дефиците еды он начнет смотреть на товарищей как на рацион.' },
  { name: 'Психопат', tier: 'C', tags: 'danger, mental', weight: -3, description: 'Не чувствует эмпатии. Легко пожертвует кем-то ради своей выгоды.' },
  { name: 'Только из очага эпидемии', tier: 'C', tags: 'danger, health', weight: -3, description: 'Может быть инкубационным носителем вируса. Опасен для всех.' },
  { name: 'Наркодилер', tier: 'C', tags: 'criminal, social', weight: -2, description: 'Мастер манипуляций, но его присутствие разлагает дисциплину.' },
  { name: 'Состоял в секте', tier: 'C', tags: 'social, mental, cult', weight: -1, description: 'Попытается превратить бункер в религиозную общину со своими правилами.' },
  { name: 'Бродяжничал 2 года', tier: 'C', tags: 'social, survival', weight: 1, description: 'Неприхотлив к еде и условиям сна. Иммунитет к грязи.' },
  { name: 'Держал 40 кошек дома', tier: 'C', tags: 'strange, annoying', weight: -1, description: 'Специфический человек с очень странными привычками гигиены.' },
  { name: 'Ранее судим за шпионаж', tier: 'C', tags: 'criminal, info', weight: 0, description: 'Никто не знает, на кого он работал и какие цели преследует сейчас.' },

  # --- Мелкие недостатки и черты характера ---
  { name: 'Безотказный', tier: 'C', tags: 'social', weight: 1, description: 'Всегда делает то, что прикажут. Идеальный чернорабочий.' },
  { name: 'Храпит как трактор', tier: 'C', tags: 'annoying', weight: -1, description: 'Звуковая атака каждую ночь. Группа будет страдать от недосыпа.' },
  { name: 'Грязно ругается', tier: 'C', tags: 'social', weight: -1, description: 'Постоянно провоцирует конфликты своим лексиконом.' },
  { name: 'Зануда', tier: 'C', tags: 'social', weight: -1, description: 'Может часами рассказывать о вреде глютена, пока за дверью зомби.' },
  { name: 'Нытик', tier: 'C', tags: 'social', weight: -2, description: 'Деморализует группу постоянными жалобами на жизнь.' },
  { name: 'Писается по ночам', tier: 'C', tags: 'hygiene', weight: -2, description: 'Серьезная проблема в условиях дефицита чистой воды и белья.' },
  { name: 'Подходит и дышит сзади', tier: 'C', tags: 'annoying, strange', weight: -1, description: 'Пугающая привычка, которая держит всех в постоянном напряжении.' },
  { name: 'Тормоз', tier: 'C', tags: 'physical', weight: -2, description: 'Медленно соображает. Опасен в ситуациях, требующих быстрой реакции.' },
  { name: 'Врет и преувеличивает', tier: 'C', tags: 'social', weight: -1, description: 'Его слова нельзя брать на веру. Возможно, половина его карт — ложь.' },
  { name: 'Клептоман', tier: 'C', tags: 'criminal, annoying', weight: -2, description: 'У других игроков начнут пропадать карты багажа.' },
  { name: 'Одержим чистотой', tier: 'C', tags: 'annoying, water', weight: -1, description: 'Будет тратить лишнюю воду на мытье рук 50 раз в день.' },
  { name: 'Спит только с включенным светом', tier: 'C', tags: 'energy, annoying', weight: -1, description: 'Лишний расход энергии бункера каждую ночь.' },
  { name: 'Боится оставаться один', tier: 'C', tags: 'mental, social', weight: -1, description: 'Будет преследовать других игроков, мешая им работать или отдыхать.' }
]

facts.each { |f| Card.create!(**f, category: 'fact') }

puts "Справочник фактов готов! Всего записей: #{Card.where(category: 'fact').count}"

puts "Успешно! База наполнена: #{Card.count} карт."

puts "Обновление справочника катастроф (40 сценариев)..."
Catastrophe.destroy_all

catastrophes = [
  # --- Основной список ---
  { name: 'Всемирный потоп', description: 'Гравитационная аномалия приводит к расширению объема воды и затоплению всей поверхности суши. Выйдя из бункера, вам предстоит построить плавучую станцию и добывать пропитание на воде.', card_bias_tags: 'survival, food, water, nature' },
  { name: 'Восстание роботов', description: 'Сперва робот Fedor захватил соцсети, а затем все электронные устройства объединились против людей. Пылесосы атакуют, телефоны прожаривают мозги. Вам предстоит объявить войну гаджетам.', card_bias_tags: 'technical, software, energy, weapon' },
  { name: 'Динозавры', description: 'Ученым удалось воскресить динозавров, но ситуация вышла из-под контроля. Стаи монстров сметают всё на пути. Вам предстоит обеспечить свое пропитание и не стать едой для новых хозяев мира.', card_bias_tags: 'weapon, security, survival, hunting' },
  { name: 'Духи и призраки', description: 'На Земле воцарилась вечная жизнь. Люди увлеклись мистикой, и призраки обрели реальную силу, проникая в головы людей. Вам нужно вычислить культурный объект, дающий им силу.', card_bias_tags: 'mental, strange, social, art' },
  { name: 'Власть алгоритмов', description: 'ИИ подчинил человечество. Сперва люди слушались автонавигатора, а теперь ИИ диктует, кем работать и когда умирать. Вам предстоит взломать программный код ИИ.', card_bias_tags: 'software, technical, info, communication' },
  { name: 'Зомби-апокалипсис', description: 'Неизвестный вирус превращает людей в зомби. После выхода из бункера вам нужно будет постоянно отбиваться от атак зомби и найти способ защититься от вируса.', card_bias_tags: 'weapon, security, medical, survival' },
  { name: 'Инопланетяне', description: 'Чужая цивилизация временно парализует человечество, чтобы принять решение о ценности нашей цивилизации. Вам нужно выйти на контакт и убедить их в ценности культуры.', card_bias_tags: 'social, art, communication, science' },
  { name: 'Инф. война', description: 'Нейронные сети начали генерировать заголовки новостей, которые сводили людей с ума. Вам нужно добраться до новостных центров и перенастроить нейронные сети.', card_bias_tags: 'software, communication, mental, info' },
  { name: 'Котопокалипсис', description: 'Эксперименты с наполнителями привели к тому, что коты научились мурчать на частотах, лишающих людей воли. Вам нужно победить котозависимость.', card_bias_tags: 'mental, nature, science, social' },
  { name: 'Мутанты', description: 'Поедание ГМО привело к страшным последствиям. Люди считают себя супергероями и сходят с ума. Вам предстоит вырастить чистые продукты и вылечить мутантов.', card_bias_tags: 'food, agriculture, medical, science' },
  { name: 'Метеорит', description: 'Крупный метеорит приближается к Земле. Столкновение приведет к смене климата и гибели флоры. Вам предстоит обеспечить пропитание в условиях вечной зимы.', card_bias_tags: 'survival, food, agriculture, physical' },
  { name: 'Пандемия', description: 'Смертельный вирус вышел из-под контроля. После выхода вас встретят мутировавшие животные и люди. Вам придется разрабатывать вакцину от вируса.', card_bias_tags: 'medical, science, healing, chemical' },
  { name: 'Русский эпос', description: 'Щуку из сказки "заклинило", она исполняет желания каждую минуту. Люди в небе, люди под землей. Нужно найти "культурный антидот", чтобы снять проклятие.', card_bias_tags: 'strange, social, art, mental' },
  { name: 'Ктулху', description: 'Распространение настольных игр привело к появлению фанатиков, призвавших Ктулху. Человечество массово теряет рассудок. Вам нужно запечатать мистические врата.', card_bias_tags: 'mental, strange, security, social' },
  { name: 'Потеря эстетики', description: 'Люди утратили чувство красоты и деградируют в диких животных. Цивилизация рухнула. Вам предстоит вернуть в мир культуру и спасти человечество.', card_bias_tags: 'art, social, mental, crafting' },
  { name: 'Страдающий Коля', description: 'Авария в ядерном центре привела к разлому времени. Средневековый эксгибиционист Коля пугает людей нашего времени. Нужно вернуть Колю в его средневековье.', card_bias_tags: 'radiation, science, technical, mental' },
  { name: 'Суицидальная фауна', description: 'Аномальный виток эволюции заставляет растения и деревья сводить людей с ума и заставлять совершать самоубийства. Нужно найти эпицентр аномалии.', card_bias_tags: 'nature, mental, medical, survival' },
  { name: 'Супервулканы', description: 'Активизируются супервулканы. Ландшафт и климат резко меняются. Вам предстоит выжить, разработав систему предсказания извержений.', card_bias_tags: 'survival, technical, science, physical' },
  { name: 'Ядерная война', description: 'Масштабный ядерный конфликт. Радиоактивная пыль окутает планету, наступит долгая ядерная зима. Нужно обустроить убежище и начать жизнь заново.', card_bias_tags: 'radiation, medical, technical, survival' },
  { name: 'Химическая война', description: 'Применение химоружия нарушило баланс. Почвы и воды отравлены. Вам пригодятся ученые и инженеры для обустройства ферм.', card_bias_tags: 'chemical, science, agriculture, medical' },

  # --- Дополнения ---
  { name: 'Солнечная вспышка', description: 'Аномальная активность Солнца выжгла всю электронику на планете. Мир вернулся в средневековье. После выхода из бункера вам придется строить цивилизацию на пару и мускульной силе.', card_bias_tags: 'crafting, physical, survival, food' },
  { name: 'Грибница (Кордицепс)', description: 'Споры разумного гриба захватили экосистему. Весь мир покрыт сетью мицелия, который реагирует на вибрации. Вам придется научиться перемещаться бесшумно и бороться с грибковыми мутациями.', card_bias_tags: 'medical, science, stealth, nature' },
  { name: 'Остановка вращения', description: 'Земля перестала вращаться. На одной стороне — вечный ледяной мрак, на другой — выжженная пустыня. Вы живете на узкой полосе сумерек, где бушуют вечные ураганы.', card_bias_tags: 'survival, technical, energy, physical' },
  { name: 'Великая тишина', description: 'Люди потеряли способность разговаривать и понимать речь. Весь мир погрузился в хаос. Вам нужно создать новый язык жестов или символов, чтобы возродить общество.', card_bias_tags: 'communication, social, art, mental' },
  { name: 'Железный голод', description: 'Особый вид бактерий начал пожирать металл. Небоскребы рушатся, техника превращается в труху. Вам предстоит освоить технологии из камня, дерева и керамики.', card_bias_tags: 'crafting, building, survival, nature' },
  { name: 'Атака насекомых', description: 'Из-за выброса гормонов насекомые выросли в десятки раз и обрели коллективный разум. Рои саранчи и гигантские муравьи доминируют на поверхности. Вам нужно найти способ сосуществования с ними.', card_bias_tags: 'nature, science, weapon, survival' },
  { name: 'Кибер-пространство', description: 'Реальность слилась с виртуальным миром. Глитчи в небе, монстры из видеоигр в лесах. Вам придется перепрограммировать реальность, чтобы выжить.', card_bias_tags: 'software, technical, mental, strange' },
  { name: 'Праздник непослушания', description: 'Все взрослые на Земле мгновенно исчезли. Остались только дети и подростки, которые за годы вашего заточения построили дикое и жестокое общество. Вам предстоит стать учителями в этом новом мире.', card_bias_tags: 'social, mental, food, security' },
  { name: 'Амнезия', description: 'Глобальный психоакустический сигнал стер память у всех выживших. Никто не помнит технологий, законов и имен. Вам предстоит заново открыть огонь и колесо.', card_bias_tags: 'survival, crafting, food, technical' },
  { name: 'Гравитационный хаос', description: 'Гравитация на планете стала нестабильной. Предметы и люди могут внезапно взлететь в воздух или стать вдесятеро тяжелее. Вам понадобятся инженеры-физики для создания зон стабильности.', card_bias_tags: 'science, technical, physical, building' },
  { name: 'Смена полюсов', description: 'Магнитное поле Земли исчезло. Космическая радиация выжигает поверхность, а навигация невозможна. Выход наружу возможен только ночью или в специальных костюмах.', card_bias_tags: 'radiation, survival, science, exploration' },
  { name: 'Мир снов', description: 'Грань между реальностью и снами стерлась. Кошмары людей материализуются наяву. Вам придется держать свой разум в чистоте, чтобы не порождать новых чудовищ.', card_bias_tags: 'mental, mental_health, strange, social' },
  { name: 'Золотая лихорадка', description: 'В атмосфере распылено вещество, превращающее любую органику в золото. Растения и животные застыли драгоценными статуями. Красиво, но есть абсолютно нечего.', card_bias_tags: 'food, agriculture, science, chemical' },
  { name: 'Нашествие теней', description: 'Существа из двухмерного измерения начали "красть" тени людей. Человек без тени медленно исчезает. Вам нужно найти способ осветить мир так, чтобы теням негде было прятаться.', card_bias_tags: 'energy, technical, strange, science' },
  { name: 'Зеркальный вирус', description: 'Всё, что вы видите, оказывается симметрично отраженным, а лево и право постоянно меняются местами. Мир превратился в лабиринт, где мозг отказывается работать. Нужно привыкнуть к новой архитектуре реальности.', card_bias_tags: 'mental, science, exploration, physical' },
  { name: 'Второе пришествие', description: 'Боги из разных пантеонов вернулись на Землю и начали делить территорию. Человечество для них — лишь пыль под ногами. Вам придется маневрировать между интересами сверхсуществ.', card_bias_tags: 'social, mental, strange, security' },
  { name: 'Эффект Манделы', description: 'Множество параллельных вселенных столкнулись. География планеты постоянно меняется, а города из разных эпох стоят рядом. Вам нужно найти способ зафиксировать свою реальность.', card_bias_tags: 'science, exploration, survival, strange' },
  { name: 'Кислородный кризис', description: 'Растения перестали вырабатывать кислород и начали выделять ядовитый хлор. Атмосфера непригодна для дыхания. Выживание возможно только в куполах и масках.', card_bias_tags: 'science, technical, medical, nature' },
  { name: 'Техно-органическая чума', description: 'Вирус превращает плоть в металл и пластик, а механизмы — в живые ткани. Машины кричат от боли, а люди становятся биороботами. Вам нужно остановить этот процесс.', card_bias_tags: 'medical, science, technical, chemical' },
  { name: 'Великая сушь', description: 'Вся вода на планете мгновенно превратилась в песок. Океаны стали огромными пустынями. Ваша единственная надежда — глубокие подземные артезианские источники.', card_bias_tags: 'water, survival, food, exploration' }
]

catastrophes.each { |c| Catastrophe.create!(c) }

puts "Справочник катастроф готов! Всего сценариев: #{Catastrophe.count}"

puts "Обновление справочника угроз (30 сценариев)..."
Threat.destroy_all

threats = [
  # --- Твой изначальный список ---
  { name: 'Затопление', description: 'В бункер проникает вода и вас может просто затопить! Нужно перенастроить компьютерную систему управления бункера или придумать какое-то инженерное решение для откачки воды.' },
  { name: 'Капча', description: 'ИИ управления бункера «заглючило» и блокирует жизнеобеспечение — необходимо доказать бездушному компьютеру наличие в бункере дышащих живых людей. Тест построен на проверке уникального отличия человека от роботов — способности к творчеству. Вам нужно пройти его.' },
  { name: 'Все спокойно', description: 'Вам повезло, обошлось без происшествий!' },
  { name: 'Землетрясение', description: 'Небольшое локальное землетрясение грозит смять ваш бункер и повредить системы жизнеобеспечения. Нужно экстренно провести работы по укреплению слабых мест — дверей и вентиляции. Или же останавливать землетрясение какой-то магией.' },
  { name: 'Нашествие крыс', description: 'Крысы добрались до ваших запасов провизии и наносят непоправимый ущерб. Вам помогут персонажи, способные истреблять грызунов или дополнительные ресурсы еды.' },
  { name: 'Кухонный взрыв', description: 'Обвал в кухонном и складском блоке. Вам помогут персонажи со знанием местности для вылазок и поиска продовольствия или способные добывать еду в подвалах бункера — устроив ферму или охоту на крыс.' },
  { name: 'Нападение извне', description: 'Какие-то дикие люди ломятся в бункер, надо срочно что-то предпринять. Вам помогут персонажи с военными навыками, охоты, обустройства сигнализации и наблюдения, запасы оружия и электроники.' },
  { name: 'Пси-атака', description: 'Вероятно, какое-то излучение усиливает стресс и наводит панику. Нужны персонажи / снаряжение, которые могут снимать стресс.' },
  { name: 'Отравление воды', description: 'Какой-то сбой с системой очистки воды. Поможет химическая фильтрация. Либо надо как-то добывать чистую воду на вылазках в окрестностях. Иначе вам потребуется медицинская помощь.' },
  { name: 'Призраки', description: 'Паранормальные явления могут нарушить систему жизнеобеспечения бункера. Вам помогут персонажи, способные убедить призраков (или что бы это ни было) покинуть бункер или же изгнать их.' },
  { name: 'Стресс-вирус', description: 'Вспышка смертельного вируса, развивающегося только на фоне стресса. Будут полезны медицинские навыки / снаряжение, а также любые способы контролировать стресс.' },

  # --- Новые угрозы (Технические и Физические) ---
  { name: 'Кислородное голодание', description: 'Система регенерации воздуха вышла из строя. Уровень CO2 растет. Нужны инженеры, физики или те, кто понимает в химии, чтобы создать кустарные поглотители углекислого газа.' },
  { name: 'Энергетический блэкаут', description: 'Главный генератор сгорел. Бункер погрузился в полную темноту. Нужны электрики или люди с мощными источниками питания (энергостанции), чтобы восстановить свет и работу дверей.' },
  { name: 'Радиационная течь', description: 'Снаружи пробило обшивку, и уровень радиации внутри начал расти. Поможет ядерный физик, архитектор (для заделки дыр) или наличие антидотов и счетчиков Гейгера.' },
  { name: 'Пожар в оранжерее', description: 'Короткое замыкание вызвало пожар там, где растет ваша еда. Нужны пожарные или люди с огнетушителями. Если не потушить — запасы еды сократятся вдвое.' },
  { name: 'Засорение вентиляции', description: 'Шахты забиты пылью и мусором. Воздух становится спертым. Нужны люди с хорошей физической подготовкой (паркур, каскадеры) или маленького роста (карлики), чтобы пролезть в узкие трубы и почистить их.' },

  # --- Биологические и Медицинские ---
  { name: 'Генетическая деградация', description: 'Из-за фона катастрофы клетки начали разрушаться. Поможет генетик или вирусолог. Если не вмешаться, к моменту выхода из бункера все будут бесплодны или тяжело больны.' },
  { name: 'Черная плесень', description: 'Стены покрылись агрессивным грибком, который пожирает запасы и вызывает галлюцинации. Помогут биологи, агрономы или химики со специфическими реактивами.' },
  { name: 'Групповой психоз', description: 'Люди начинают видеть в товарищах врагов. Напряжение на пределе. Поможет психиатр, священник или наличие успокоительных и алкоголя в багаже.' },
  { name: 'Сонная одурь', description: 'Неизвестный газ просочился в спальный отсек. Всех клонит в сон, никто не хочет работать. Помогут фармакологи или те, у кого в багаже есть кофе и бодрящие средства.' },

  # --- Социальные и Юридические ---
  { name: 'Саботаж', description: 'Кто-то намеренно портит оборудование и ворует еду. В бункере «крыса». Нужен детектив, спецагент или полицейский, чтобы вычислить вредителя.' },
  { name: 'Бюрократический тупик', description: 'Автоматическая система требует подтверждения прав на управление ресурсами. Без юриста, судьи или адвоката вы не сможете открыть склад с деликатесами.' },
  { name: 'Религиозный раскол', description: 'Один из членов группы объявил себя пророком и требует жертвоприношений. Нужен священник, психолог или сильный лидер, чтобы успокоить паству.' },
  { name: 'Культурная депрессия', description: 'Отсутствие развлечений приводит к апатии. Все сидят и смотрят в стену. Помогут артисты, писатели, блогеры или наличие настолок и гитары.' },

  # --- Сюрреалистичные и Редкие ---
  { name: 'Временная петля', description: 'Один и тот же день в бункере начал повторяться. Поможет физик, телепат или тот, кто читал много научной фантастики, чтобы найти выход из аномалии.' },
  { name: 'Информационный вирус', description: 'Ваш единственный ноутбук начал транслировать пугающие сообщения, которые зомбируют группу. Нужен хакер, программист или видеоинженер, чтобы выключить это.' },
  { name: 'Бунт ИИ (младшая модель)', description: 'Ваша кофеварка и робот-психолог объединились и заперли вас в столовой. Нужен робототехник или электрик, чтобы «переубедить» технику.' },
  { name: 'Эффект тишины', description: 'Любые звуки выше шепота вызывают болезненные вибрации стен. Нужно общаться жестами. Поможет переводчик, мим или те, кто владеет языком глухонемых.' },
  { name: 'Золотая пыль', description: 'Система очистки воздуха начала выдавать микрочастицы золота. Красиво, но легкие забиваются. Нужен химик для очистки фильтров или ювелир/кузнец для сбора «урожая».' },
  { name: 'Пропажа туалетной бумаги', description: 'Настоящая катастрофа внутри катастрофы. Моральный дух на нуле. Нужен мастер на все руки (разнорабочий) или тот, у кого в багаже есть хоть какая-то бумага/газеты.' }
]

threats.each { |t| Threat.create!(t) }

puts "Справочник угроз готов! Всего в базе: #{Threat.count}"

puts "Обновление справочника особенностей бункера (55 позиций)..."
BunkerFeature.destroy_all

features = [
  # --- Твой изначальный список ---
  { name: 'Силовое поле', description: 'Переносной генератор защитного силового поля.' },
  { name: 'Подвал', description: 'Бункер строили заключенные. Жуткий запах привел вас в подвал, где вы нашли их останки, инструменты и оружие охранников.' },
  { name: 'Радио', description: 'По внутреннему радио классическую музыку постоянно сменяет Киркоров. Можно потренировать стрессоустойчивость.' },
  { name: 'Уклон 45°', description: 'В результате тектонических сдвигов бункер слегка наклонен. Где-то на 45 градусов.' },
  { name: 'Некрономикон', description: 'Огромный древний фолиант на неизвестном языке с мистическими иллюстрациями. Похоже на гримуар и анатомическую энциклопедию.' },
  { name: 'Робот-полиграф', description: 'Автономный робот-переводчик с функцией полиграфа. Пригодится для сложных переговоров.' },
  { name: 'Шкаф с настолками', description: 'Шкаф с настольными играми! Погодите-ка, но тут только всевозможные виды Монополии... Хорошо, что нам некуда спешить.' },
  { name: 'Учебник', description: 'Учебное пособие «Как убедить зомби не жрать ваш мозг».' },
  { name: 'Хим. лаборатория', description: 'Хим. лаборатория и реактивы. Можно устроить гидропоническую ферму.' },
  { name: 'Мастерская', description: 'Мастерская с инструментами.' },
  { name: 'Кофе', description: 'Кофемолка и запас ароматного обжаренного зернового кофе. Напоминание о нормальной жизни.' },
  { name: 'Крысы', description: 'Похоже, что в бункере обитают полчища крыс. В критической ситуации или мы для них еда, или они для нас.' },
  { name: 'Книга о еде', description: 'Книга «О вкусной и здоровой пище» с главами о том, как готовить даже в самых экстремальных условиях.' },
  { name: 'Катакомбы', description: 'Из подвала есть выход в естественный грот с подземной рекой. По ней можно попасть в городскую канализацию.' },
  { name: 'Керосиновые лампы', description: 'С перебоями работает электричество, но есть керосиновые лампы и запас топлива. Коктейли Молотова пригодятся.' },
  { name: 'Мед. лаборатория', description: 'Медицинская лаборатория с операционной.' },
  { name: 'Медиатека', description: 'Есть автономная медиатека, но в ней только порнофильмы — кажется, за всю историю кинематографа.' },
  { name: 'Мусор', description: 'Дырявые матрасы и тряпки, брошенный строительный мусор. Среди мусора — старинные газеты 2020-го года!' },
  { name: 'Жертвенник', description: 'Спальных мест ровно по числу людей. Одно из них стоит обособленно и похоже на жертвенный алтарь.' },
  { name: 'Гречка', description: 'Из запасов продовольствия только гречка. Зато очень много, похоже на двойной запас.' },
  { name: 'Динамо-машина', description: 'Резервный электрогенератор с велоприводом и куча металлолома.' },
  { name: 'Голосовое управление', description: 'Бункером управляет ИИ с голосовым интерфейсом. Команды он понимает с пятой попытки.' },
  { name: 'Вместе на 10 лет', description: 'Этот бункер откроется и выпустит вас только через 10 лет. Запас еды соответствующий.' },
  { name: 'Гипномодуль', description: 'Модуль гипно-телепатической коммуникации и детектор паранормальных полей.' },
  { name: 'Загадочный журнал', description: 'Старый журнал, в котором имена всех из вашей команды. Рядом даты 33-летней давности и описание будущего.' },
  { name: 'Записи контрабандиста', description: 'Библиотека контрабандиста. Детально описаны все ценные предметы искусства в округе и маршруты вывоза.' },
  { name: 'Инструкция к микроволновке', description: 'Нет туалетной бумаги, но есть инструкция по перепрограммированию микроволновки на 7174 языках.' },
  { name: 'Видео со спутника', description: 'На стены проецируется релаксационное видео съемок окрестностей бункера со спутника.' },
  { name: 'R2D2', description: 'Робот-психолог. Молча слушаете и кивает, иногда что-то пиликает. Пригодится на запчасти.' },
  { name: 'Аптечки', description: 'У входа есть аптечки, резиновые перчатки, маски и огнетушитель.' },

  # --- Новые дополнения ---
  { name: 'Вертикальная ферма', description: 'Автоматизированные стеллажи для выращивания зелени. Требуют много воды, но дают свежие витамины.' },
  { name: 'Серверная', description: 'Стойка с работающими серверами локальной сети. Хранит терабайты довоенных знаний, но сильно греет воздух.' },
  { name: 'Тир', description: 'Небольшое помещение для стрельбы. Позволяет поддерживать навыки владения оружием в тонусе.' },
  { name: 'Дренажная система', description: 'Надежная система отвода грунтовых вод. Защитит бункер от затопления.' },
  { name: 'Оружейный сейф', description: 'Запертый стальной шкаф. Кода никто не знает, но внутри явно что-то тяжелое и металлическое.' },
  { name: 'Спортивный уголок', description: 'Пара ржавых гантелей, турник и беговая дорожка, работающая от трения. Поможет не атрофироваться мышцам.' },
  { name: 'Гриль-установка', description: 'Профессиональная вытяжка и плита. Позволяет готовить пищу без дыма и запаха, не выдавая местоположение бункера.' },
  { name: 'Сауна', description: 'Удивительно, но в этом бункере есть рабочая сауна. Единственный способ по-настоящему помыться и снять стресс.' },
  { name: 'Система «Умный дом»', description: 'Свет включается по хлопку, но иногда он путает хлопок с кашлем и начинает мигать как в дискотеке.' },
  { name: 'Герметичные шлюзы', description: 'Двойная система дверей с дезинфекцией. Защитит от вирусов и радиации снаружи.' },
  { name: 'Подземный источник', description: 'Естественный ключ с чистой водой прямо в стене. Вы никогда не умрете от жажды.' },
  { name: 'Свалка запчастей', description: 'Гора старой бытовой техники. Из этого хлама инженер сможет собрать почти что угодно.' },
  { name: 'Набор для виноделия', description: 'Бочки, пресс и концентраты. Позволяет производить спиртное прямо на месте.' },
  { name: 'Сейсмограф', description: 'Чувствительный прибор, фиксирующий малейшие колебания почвы. Предупредит о землетрясении за час.' },
  { name: 'Люк в потолке', description: 'Замаскированный выход на крышу здания над бункером. Позволяет вести наблюдение, не выходя через главную дверь.' },
  { name: 'Коллекция семян', description: 'Герметичный кейс с семенами редких лекарственных растений и цветов.' },
  { name: 'Вентилятор-гигант', description: 'Огромная лопастная система. Работает шумно, но вытягивает любой дым и газы за секунды.' },
  { name: 'Запасы шоколада', description: 'Скрытый ящик с армейским горьким шоколадом. Невероятный ресурс для обмена и поднятия духа.' },
  { name: 'Детская комната', description: 'Помещение с игрушками и двухъярусными кроватями. Выглядит жутковато, но напоминает о будущем.' },
  { name: 'Мастерская швеи', description: 'Несколько ручных швейных машинок и рулоны плотной ткани. Можно шить тенты и одежду.' },
  { name: 'Астрономический календарь', description: 'Механические часы, показывающие фазы луны и положение планет. Поможет не потерять счет времени.' },
  { name: 'Яма с известью', description: 'Санитарная зона для утилизации отходов. Пахнет плохо, но необходимо для гигиены.' },
  { name: 'Проигрыватель винила', description: 'И коллекция пластинок. Музыка без цифры и помех. Очень уютно.' },
  { name: 'Запас фильтров', description: 'Целый стеллаж сменных картриджей для системы очистки воздуха. Вы проживете долго.' },
  { name: 'Эхолот', description: 'Прибор для сканирования пустот за стенами. Позволяет слышать, что происходит снаружи или в соседних тоннелях.' }
]

features.each { |f| BunkerFeature.create!(f) }

puts "Справочник особенностей бункера готов! Всего позиций: #{BunkerFeature.count}"

puts "Обновление справочника карт действий (40 позиций)..."
ActionCard.destroy_all

action_cards = [
  # --- ГЛОБАЛЬНЫЕ ПЕРЕМЕШИВАНИЯ (Automated) ---
  { name: 'Давайте начистоту (Багаж)', card_type: 'automated', code: 'shuffle_luggage', requires_target: false, description: 'Собери все ОТКРЫТЫЕ карты багажа у неизгнанных игроков, перемешай и перераздай.' },
  { name: 'Давайте начистоту (Здоровье)', card_type: 'automated', code: 'shuffle_health', requires_target: false, description: 'Собери все ОТКРЫТЫЕ карты здоровья у неизгнанных игроков, перемешай и перераздай.' },
  { name: 'Давайте начистоту (Хобби)', card_type: 'automated', code: 'shuffle_hobbies', requires_target: false, description: 'Собери все ОТКРЫТЫЕ карты хобби у неизгнанных игроков, перемешай и перераздай.' },
  { name: 'Давайте начистоту (Факты)', card_type: 'automated', code: 'shuffle_facts', requires_target: false, description: 'Собери все ОТКРЫТЫЕ карты фактов у неизгнанных игроков, перемешай и перераздай.' },
  { name: 'Давайте начистоту (Биология)', card_type: 'automated', code: 'shuffle_biology', requires_target: false, description: 'Собери всю ОТКРЫТУЮ биологию у неизгнанных игроков и перераздай.' },
  { name: 'Профориентация', card_type: 'automated', code: 'reroll_all_professions', requires_target: false, description: 'Всем игрокам без исключения меняются профессии на новые случайные из колоды.' },

  # --- НАПРАВЛЕННЫЕ НА ЦЕЛЬ (Automated) ---
  { name: 'Обмен (Багаж)', card_type: 'automated', code: 'swap_luggage', requires_target: true, description: 'Поменяйся открытыми картами багажа с выбранным игроком.' },
  { name: 'Обмен (Здоровье)', card_type: 'automated', code: 'swap_health', requires_target: true, description: 'Поменяйся открытыми картами здоровья с выбранным игроком.' },
  { name: 'Обмен (Хобби)', card_type: 'automated', code: 'swap_hobbies', requires_target: true, description: 'Поменяйся открытыми картами хобби с выбранным игроком.' },
  { name: 'Обмен (Факты)', card_type: 'automated', code: 'swap_facts', requires_target: true, description: 'Поменяйся открытыми картами фактов с выбранным игроком.' },
  { name: 'Просроченные таблетки', card_type: 'automated', code: 'reroll_health', requires_target: true, description: 'Замени открытую карту Здоровья выбранного игрока на случайную из колоды.' },
  { name: 'Фейковый диплом', card_type: 'automated', code: 'reroll_profession', requires_target: true, description: 'Смени открытую карту Профессии выбранного игрока на случайную из колоды.' },
  { name: 'Хорошие таблетки', card_type: 'automated', code: 'heal_health', requires_target: true, description: 'Делает выбранного игрока "Идеально здоровым".' },
  { name: 'Сеанс психотерапии', card_type: 'automated', code: 'heal_phobia', requires_target: true, description: 'Полностью избавляет выбранного игрока от фобии ("Нет фобий").' },

  # --- НОВЫЕ СИЛЬНЫЕ МЕХАНИКИ (Automated) ---
  { name: 'Второе дыхание', card_type: 'automated', code: 'cure_infertility', requires_target: true, description: 'Выбранный игрок излечивается от бесплодия (становится способен к размножению).' },
  { name: 'Эликсир молодости', card_type: 'automated', code: 'make_young', requires_target: true, description: 'Выбранный игрок становится молодым (случайный возраст 18-25 лет).' },
  { name: 'Сыворотка правды', card_type: 'automated', code: 'reveal_all', requires_target: true, description: 'Выбранный игрок обязан вскрыть ВСЕ свои карты прямо сейчас.' },
  { name: 'Лишний билет', card_type: 'automated', code: 'increase_capacity', requires_target: false, description: 'Вместимость бункера увеличивается на +1 место.' },
  { name: 'Двери заклинило', card_type: 'automated', code: 'decrease_capacity', requires_target: false, description: 'Вместимость бункера уменьшается на -1 место.' },
  { name: 'Обыск', card_type: 'automated', code: 'steal_luggage', requires_target: true, description: 'Забери себе открытый багаж выбранного игрока. У него в слоте багажа станет пусто.' },

  # --- СОЦИАЛЬНЫЕ (Social - отыгрыш голосом) ---
  { name: 'Отмена действия', card_type: 'social', code: 'cancel_action', requires_target: false, description: 'Отменяет действие карточки, которую только что сыграл другой игрок.' },
  { name: 'Будь другом', card_type: 'social', code: 'immunity_vote', requires_target: true, description: 'Выбранный игрок до конца игры не голосует против тебя.' },
  { name: 'Громкий голос', card_type: 'social', code: 'double_vote', requires_target: false, description: 'Твой голос считается за два в этом раунде.' },
  { name: 'План Б', card_type: 'social', code: 'revote', requires_target: false, description: 'Все должны переголосовать заново в этом раунде.' },
  { name: 'Молчание', card_type: 'social', code: 'silence', requires_target: true, description: 'Игрок больше не говорит в этом раунде. Только жесты.' },
  { name: 'Прямой вопрос', card_type: 'social', code: 'force_reveal_type', requires_target: false, description: 'Выбери тип карт (напр. Фобия). Все обязаны вскрыть карты этого типа в свой следующий ход.' },
  { name: 'Дискредитация', card_type: 'social', code: 'nullify_vote', requires_target: true, description: 'Голос выбранного игрока не учитывается в этом раунде.' },
  { name: 'Защити соседа', card_type: 'social', code: 'protect_neighbor', requires_target: false, description: 'Если изгнан игрок слева от вас, в следующий раз вы голосуете против себя.' },
  { name: 'Компромат', card_type: 'social', code: 'double_vote_against', requires_target: true, description: 'Голоса против выбранного игрока удваиваются.' },
  { name: 'Иммунитет', card_type: 'social', code: 'round_immunity', requires_target: true, description: 'Против выбранного игрока (можно себя) нельзя голосовать в этом раунде.' },
  { name: 'Взял с собой', card_type: 'social', code: 'take_from_bunker', requires_target: false, description: 'Только если ты ИЗГНАН. Забери из бункера любую вскрытую особенность (напр. Аптечки). Группа их лишается.' },
  { name: 'Диверсия', card_type: 'social', code: 'sabotage_bunker', requires_target: false, description: 'Только если ты ИЗГНАН. Сбрось любую открытую карту бункера. Группа ее теряет.' },
  { name: 'Тайная угроза', card_type: 'social', code: 'extra_threat', requires_target: false, description: 'В финале ИИ добавит в историю банду мародеров, преследующих бункер.' }
]

action_cards.each { |ac| ActionCard.create!(ac) }

puts "Обновление справочника рейдов (50 сценариев)..."
Raid.destroy_all

raids = [
  # --- Твой изначальный список (с уточненными тегами) ---
  { name: "Заброшенная аптека", description: "Поиск медикаментов в руинах города.", required_tags: "medical, stealth", dangerous_tags: "disease" },
  { name: "Военный склад", description: "Попытка раздобыть оружие и патроны.", required_tags: "security, weapon", dangerous_tags: "danger" },
  { name: "Библиотека", description: "Поиск знаний и карт местности.", required_tags: "intelligence, history", dangerous_tags: "panic" },
  { name: "Грозовой перевал", description: "Установка радиовышки для связи.", required_tags: "technical, physical, communication", dangerous_tags: "danger" },
  { name: "Затопленный супермаркет", description: "Поиск консервов в подвальных этажах.", required_tags: "physical, survival, water", dangerous_tags: "water" },
  { name: "Покинутая лаборатория", description: "Сбор химреактивов для фильтров.", required_tags: "science, chemical", dangerous_tags: "radiation" },
  { name: "Гнездо крыс", description: "Зачистка окрестностей от вредителей.", required_tags: "hunting, weapon", dangerous_tags: "infection" },
  { name: "Огород на крыше", description: "Сбор семян и удобрений из теплиц.", required_tags: "agriculture, farming", dangerous_tags: "open_space, height" },
  { name: "Полицейский участок", description: "Поиск наручников и бронежилетов.", required_tags: "security, combat", dangerous_tags: "criminal" },
  { name: "Разрушенный банк", description: "Поиск золотых слитков или ключей от хранилищ.", required_tags: "stealth, mechanical, logic", dangerous_tags: "dark" },
  { name: "Автомастерская", description: "Поиск запчастей для генератора.", required_tags: "repair, technical", dangerous_tags: "heavy_objects" },
  { name: "Старый приют", description: "Поиск детского питания и одежды.", required_tags: "social, mental_health", dangerous_tags: "panic" },
  { name: "Рыболовная хижина", description: "Добыча рыбы на радиоактивном озере.", required_tags: "food, survival", dangerous_tags: "water, radiation" },
  { name: "Завод электроники", description: "Поиск плат и микросхем.", required_tags: "software, robotic, technical", dangerous_tags: "tech" },
  { name: "Офис президента", description: "Поиск секретных кодов доступа.", required_tags: "authority, logic, info", dangerous_tags: "security" },
  { name: "Охотничьи угодья", description: "Выслеживание крупной дичи.", required_tags: "tracking, weapon, hunting", dangerous_tags: "dogs" },
  { name: "Чердак художника", description: "Поиск материалов для творчества.", required_tags: "art, intelligence", dangerous_tags: "height" },
  { name: "Подземные тоннели", description: "Разведка нового пути выхода.", required_tags: "exploration, dark", dangerous_tags: "confined, dark" },
  { name: "Сгоревший госпиталь", description: "Поиск хирургических инструментов.", required_tags: "surgery, medical", dangerous_tags: "blood, fire" },
  { name: "Винный погреб", description: "Сбор спиртного для медицинских нужд.", required_tags: "alcohol, food", dangerous_tags: "dark" },
  { name: "Святилище секты", description: "Переговоры с местными безумцами.", required_tags: "social, language, cult", dangerous_tags: "cult" },
  { name: "Мастерская плотника", description: "Сбор древесины и инструментов.", required_tags: "building, physical", dangerous_tags: "injury" },
  { name: "Музей авиации", description: "Поиск легкого транспорта или запчастей.", required_tags: "transport, intelligence", dangerous_tags: "height" },
  { name: "Радиоцентр", description: "Попытка перехватить сигнал извне.", required_tags: "communication, technical", dangerous_tags: "tech" },
  { name: "Брошенный караван", description: "Обыск вещей других беженцев.", required_tags: "stealth, survival", dangerous_tags: "danger" },

  # --- Новые рейды (с 26 по 50) ---
  { name: "Заброшенный космодром", description: "Поиск высокотехнологичного топлива.", required_tags: "science, technical", dangerous_tags: "radiation" },
  { name: "Парк аттракционов", description: "Демонтаж мощных электродвигателей.", required_tags: "technical, repair", dangerous_tags: "height, panic" },
  { name: "Очистные сооружения", description: "Замена фильтрующих элементов города.", required_tags: "technical, water", dangerous_tags: "infection, water" },
  { name: "Ботанический сад", description: "Поиск редких лекарственных трав.", required_tags: "agriculture, nature, medical", dangerous_tags: "bugs" },
  { name: "Подземная серверная", description: "Копирование базы данных знаний.", required_tags: "software, intelligence", dangerous_tags: "dark, confined" },
  { name: "Грузовой порт", description: "Обыск морских контейнеров.", required_tags: "transport, physical", dangerous_tags: "water, heavy_objects" },
  { name: "Место падения метеорита", description: "Сбор образцов внеземного металла.", required_tags: "science, radiation", dangerous_tags: "radiation" },
  { name: "Полицейская академия", description: "Поиск спецсредств разгона толпы.", required_tags: "security, weapons", dangerous_tags: "criminal" },
  { name: "Секретный бункер связи", description: "Вскрытие защищенного терминала.", required_tags: "technical, building, software", dangerous_tags: "confined" },
  { name: "Химкомбинат", description: "Добыча чистого спирта и реагентов.", required_tags: "science, chemical", dangerous_tags: "injury, chemical" },
  { name: "Горная обсерватория", description: "Наблюдение за звездами и атмосферой.", required_tags: "science, intelligence", dangerous_tags: "height" },
  { name: "Крыша небоскреба", description: "Подача светового сигнала спасателям.", required_tags: "risk, physical", dangerous_tags: "height, open_space" },
  { name: "Заброшенная пивоварня", description: "Поиск дрожжей и солода.", required_tags: "food, alcohol", dangerous_tags: "dark" },
  { name: "Галерея искусств", description: "Спасение культурного наследия.", required_tags: "art, social", dangerous_tags: "social" },
  { name: "Приют для животных", description: "Поиск выживших служебных собак.", required_tags: "dogs, social", dangerous_tags: "dogs" },
  { name: "Строительный гипермаркет", description: "Сбор цемента и арматуры.", required_tags: "repair, building", dangerous_tags: "injury, heavy_objects" },
  { name: "Жерло спящего вулкана", description: "Установка сейсмических датчиков.", required_tags: "science, risk", dangerous_tags: "fire, danger" },
  { name: "Элитный отель", description: "Поиск предметов роскоши для обмена.", required_tags: "social, stealth", dangerous_tags: "social" },
  { name: "Радиоактивный лес", description: "Охота на мутировавшую дичь.", required_tags: "nature, survival, hunting", dangerous_tags: "radiation" },
  { name: "Старое кладбище", description: "Поиск исторических документов в склепах.", required_tags: "history, social", dangerous_tags: "panic, dark" },
  { name: "Заброшенный цирк", description: "Поиск фургонов и грима.", required_tags: "social, art", dangerous_tags: "panic" },
  { name: "Тюрьма строгого режима", description: "Поиск бронированных дверей и решеток.", required_tags: "security, combat", dangerous_tags: "criminal, danger" },
  { name: "Старая шахта", description: "Добыча угля для отопления.", required_tags: "exploration, technical", dangerous_tags: "confined, dark" },
  { name: "Научно-исследовательское судно", description: "Поиск глубоководного оборудования.", required_tags: "science, water", dangerous_tags: "water" },
  { name: "Музей естествознания", description: "Поиск скелетов для костной муки (удобрение).", required_tags: "science, history", dangerous_tags: "panic" }
]

raids.each { |r| Raid.create!(r) }

puts "Справочник рейдов готов! Всего сценариев: #{Raid.count}"
