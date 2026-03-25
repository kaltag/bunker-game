# db/seeds.rb
puts "Полная очистка старых данных..."
Game.destroy_all
PlayerCard.delete_all
Player.delete_all
Card.destroy_all

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

puts "Создание здоровья (расширенный список)..."
healths = [
  # --- Tier S (Отличное или скрытое состояние) ---
  { name: 'Идеально здоров', tier: 'S', tags: 'healthy', weight: 2, description: 'Никаких жалоб, идеальные показатели.', is_curable: true },
  { name: 'Не обследовался', tier: 'S', tags: 'unknown', weight: 0, description: 'Чувствует себя нормально, но кто знает, что внутри...', is_curable: true },

  # --- Tier A (Мелкие странности или легкие дефекты) ---
  { name: 'Повышенная волосатость', tier: 'A', tags: 'physical, cosmetic', weight: 0, description: 'Густая шерсть по всему телу. Зимой даже плюс.', is_curable: false },
  { name: 'Потеря обоняния', tier: 'A', tags: 'sensory', weight: 0, description: 'Не чувствует запахов. Полезно при очистке туалетов в бункере.', is_curable: true },
  { name: 'Хвост', tier: 'A', tags: 'physical, genetic', weight: -1, description: 'Небольшой рудиментарный отросток. Слегка мешает сидеть.', is_curable: false },
  { name: 'Кофейная зависимость', tier: 'A', tags: 'addiction', weight: -1, description: 'Без чашки кофе по утрам становится очень раздражительным.', is_curable: true },

  # --- Tier B (Зависимости и управляемые проблемы) ---
  { name: 'Заика', tier: 'B', tags: 'physical, social', weight: -1, description: 'Трудно говорить в стрессовых ситуациях.', is_curable: true },
  { name: 'Фригидность / Импотенция', tier: 'B', tags: 'reproduction, physical', weight: -1, description: 'Проблемы в интимной сфере.', is_curable: true },
  { name: 'Мигрень', tier: 'B', tags: 'physical, pain', weight: -1, description: 'Периодические приступы сильнейшей головной боли.', is_curable: true },
  { name: 'Понос', tier: 'B', tags: 'physical, infection', weight: -1, description: 'Кишечное расстройство. Требует много воды и бумаги.', is_curable: true },
  { name: 'Клептомания', tier: 'B', tags: 'mental, addiction', weight: -2, description: 'Непреодолимое желание прибрать к версиям чужие вещи.', is_curable: true },
  { name: 'Игровая зависимость', tier: 'B', tags: 'mental, addiction', weight: -1, description: 'Готов спорить и играть на что угодно.', is_curable: true },

  # --- Tier C (Серьезные физические и ментальные травмы) ---
  { name: 'Бесплодие', tier: 'C', tags: 'reproduction', weight: -2, description: 'Не может иметь детей. Удар по будущему популяции.', is_curable: false },
  { name: 'Слепой', tier: 'C', tags: 'sensory, disability', weight: -4, description: 'Полная темнота. Нуждается в постоянной опеке.', is_curable: false },
  { name: 'Глухой', tier: 'C', tags: 'sensory, disability', weight: -3, description: 'Не слышит звуков. Нужен сурдоперевод или переписка.', is_curable: false },
  { name: 'Нет ноги', tier: 'C', tags: 'physical, disability', weight: -3, description: 'Передвигается на костылях или протезе.', is_curable: false },
  { name: 'Нет руки', tier: 'C', tags: 'physical, disability', weight: -3, description: 'Сложно выполнять любую физическую работу.', is_curable: false },
  { name: 'Тремор рук', tier: 'C', tags: 'physical, neurological', weight: -2, description: 'Руки постоянно дрожат. Не может делать точную работу.', is_curable: true },
  { name: 'Карлик', tier: 'C', tags: 'physical, genetic', weight: -1, description: 'Очень низкий рост. Свои плюсы и минусы в быту.', is_curable: false },
  { name: 'Гигантизм отдельных частей тела', tier: 'C', tags: 'physical, genetic', weight: -2, description: 'Например, одна рука в два раза больше другой.', is_curable: false },

  # --- Tier C (Ментальные расстройства) ---
  { name: 'Депрессия', tier: 'C', tags: 'mental', weight: -2, description: 'Постоянная апатия и отсутствие желания бороться за жизнь.', is_curable: true },
  { name: 'Галлюцинации', tier: 'C', tags: 'mental', weight: -3, description: 'Видит и слышит то, чего нет на самом деле.', is_curable: true },
  { name: 'Раздвоение личности', tier: 'C', tags: 'mental', weight: -3, description: 'Внутри живут два разных человека с разными именами.', is_curable: true },
  { name: 'Мания преследования', tier: 'C', tags: 'mental', weight: -2, description: 'Уверен, что другие игроки хотят его убить.', is_curable: true },
  { name: 'Лунатизм', tier: 'C', tags: 'mental', weight: -2, description: 'Ходит и разговаривает во сне. Может выйти из бункера.', is_curable: true },
  { name: 'Склероз', tier: 'C', tags: 'mental, memory', weight: -2, description: 'Забывает события, имена и где оставил вещи.', is_curable: true },
  { name: 'Суицидальные мысли', tier: 'C', tags: 'mental', weight: -3, description: 'Опасен для самого себя, нужен постоянный присмотр.', is_curable: true },
  { name: 'Сексуальная озабоченность', tier: 'C', tags: 'mental, social', weight: -2, description: 'Постоянно донимает окружающих непристойностями.', is_curable: true },

  # --- Тяжелые зависимости ---
  { name: 'Алкоголизм', tier: 'C', tags: 'addiction, physical', weight: -2, description: 'При отсутствии спиртного начинается тяжелая ломка.', is_curable: true },
  { name: 'Зависимость от наркотиков', tier: 'C', tags: 'addiction, physical', weight: -3, description: 'Нуждается в регулярной дозе сильных препаратов.', is_curable: true }
]

healths.each { |h| Card.create!(**h, category: 'health') }

puts "Создание багажа (расширенный список)..."
luggages = [
  # --- Tier S (Критически важны: медицина, возобновляемая еда, энергия) ---
  { name: 'Инкубатор с яйцами', tier: 'S', tags: 'food, farming, birds', weight: 4, description: 'Шанс завести собственную птицеферму внутри бункера.' },
  { name: 'Саженцы фруктовых деревьев', tier: 'S', tags: 'food, farming', weight: 4, description: 'Основа для будущего сада. Требуют ухода и места.' },
  { name: 'Переносная электростанция', tier: 'S', tags: 'energy, technical', weight: 4, description: 'Заряжается от солнца или движения. Даст свет и ток.' },
  { name: 'Антибиотики и обезболивающее', tier: 'S', tags: 'medical, healing', weight: 3, description: 'Запас сильных лекарств на экстренный случай.' },
  { name: 'Чемоданчик фельдшера', tier: 'S', tags: 'medical, healing', weight: 3, description: 'Профессиональный набор инструментов для первой помощи.' },
  { name: 'Снайперская винтовка', tier: 'S', tags: 'security, weapon', weight: 3, description: 'Позволит контролировать периметр на дальних дистанциях.' },

  # --- Tier A (Очень полезны: инструменты, еда, защита) ---
  { name: 'Мешок зерна', tier: 'A', tags: 'food, farming', weight: 2, description: 'Можно съесть сейчас или посадить для получения урожая.' },
  { name: 'Мешок картошки', tier: 'A', tags: 'food, farming', weight: 2, description: 'Стратегический запас углеводов и семенной фонд.' },
  { name: 'Инструменты электрика', tier: 'A', tags: 'technical, energy, repair', weight: 2, description: 'Мультиметр, паяльник и кусачки. Незаменимы при поломках.' },
  { name: 'Прибор ночного видения', tier: 'A', tags: 'security, exploration', weight: 2, description: 'Дает преимущество в темноте за пределами бункера.' },
  { name: 'Пистолет', tier: 'A', tags: 'security, weapon', weight: 2, description: 'Компактное средство самообороны.' },
  { name: 'Дефибриллятор', tier: 'A', tags: 'medical, energy', weight: 2, description: 'Может спасти жизнь при остановке сердца. Нужен ток.' },
  { name: 'Звуковая отвертка', tier: 'A', tags: 'technical, repair', weight: 2, description: 'Странный высокотехнологичный гаджет. Чинит почти всё.' },

  # --- Tier B (Полезные инструменты и навыки) ---
  { name: 'Лук и стрелы', tier: 'B', tags: 'security, weapon, hunting', weight: 1, description: 'Бесшумное оружие. Стрелы можно изготовить самому.' },
  { name: 'Компас и карта окрестностей', tier: 'B', tags: 'exploration, survival', weight: 1, description: 'Помогут не заблудиться при вылазках за ресурсами.' },
  { name: 'Набор отмычек', tier: 'B', tags: 'stealth, survival', weight: 1, description: 'Позволит вскрыть заброшенные склады и аптеки.' },
  { name: 'Капканы и набор ядов', tier: 'B', tags: 'hunting, security', weight: 1, description: 'Эффективно для добычи еды и защиты от незваных гостей.' },
  { name: 'Ножи для метания', tier: 'B', tags: 'security, weapon', weight: 1, description: 'Требуют мастерства, но не шумят и не требуют патронов.' },
  { name: 'Столярные инструменты', tier: 'B', tags: 'technical, building', weight: 1, description: 'Пилы, стамески, рубанки. Полезны для обустройства быта.' },
  { name: 'Ноутбук и платы Arduino', tier: 'B', tags: 'technical, software', weight: 1, description: 'Для создания простых систем автоматизации или связи.' },
  { name: 'Энциклопедия грибника', tier: 'B', tags: 'food, survival', weight: 1, description: 'Поможет отличить сытный обед от смертельного ужина.' },

  # --- Tier C (Малополезные, социальные или "балласт") ---
  { name: 'Гитара', tier: 'C', tags: 'social, mental', weight: 0, description: 'Развлечение и поднятие духа в депрессивном бункере.' },
  { name: 'Настольные игры', tier: 'C', tags: 'social, mental', weight: 0, description: 'Помогут не сойти с ума от скуки в течение 5 лет.' },
  { name: 'Книги Айзека Азимова', tier: 'C', tags: 'mental, education', weight: 0, description: 'Классика научной фантастики. Напоминание о былом величии.' },
  { name: '3 слитка золота', tier: 'C', tags: 'wealth, ballast', weight: -1, description: 'Красиво блестят, но в новом мире на них ничего не купишь.' },
  { name: 'Спиритическая доска', tier: 'C', tags: 'strange, mental', weight: -1, description: 'Для общения с духами тех, кто не попал в бункер.' },
  { name: 'Кукла вуду', tier: 'C', tags: 'strange', weight: -1, description: 'Попытка контролировать врагов магией. Вряд ли сработает.' },
  { name: 'Миллион долларов', tier: 'C', tags: 'wealth, ballast', weight: -2, description: 'Куча крашеной бумаги. Отлично подходит для растопки печи.' },
  { name: 'Надувная кукла', tier: 'C', tags: 'strange, social', weight: -1, description: 'Очень странный предмет для выживания. Вызывает вопросы.' },
  { name: 'Шапочка из фольги', tier: 'C', tags: 'joke, mental', weight: -2, description: 'Защищает от рептилоидов и 5G. По крайней мере, вы в это верите.' }
]

luggages.each { |l| Card.create!(**l, category: 'luggage') }

puts "Создание фобий (полный список 30+)..."
phobias = [
  # --- Tier S (Кремень) ---
  { name: 'Нет фобий', tier: 'S', tags: 'brave, mental', weight: 1, description: 'Психика непоколебима. Способен сохранять рассудок в любой ситуации.', is_curable: true },

  # --- Tier A (Легкие или специфические страхи) ---
  { name: 'Арахнофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь пауков. Будет кричать при виде любого насекомого.', is_curable: true },
  { name: 'Айхмофобия', tier: 'A', tags: 'panic, mental, sharp', weight: -1, description: 'Боязнь острых предметов. Не сможет пользоваться ножом или скальпелем.', is_curable: true },
  { name: 'Кинофобия', tier: 'A', tags: 'panic, mental, dogs', weight: -1, description: 'Боязнь собак. Проблема, если у группы есть пес-охранник.', is_curable: true },
  { name: 'Айлурофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь кошек. Нервничает, если рядом пушистый зверь.', is_curable: true },
  { name: 'Спектрофобия', tier: 'A', tags: 'panic, mental', weight: -1, description: 'Боязнь зеркал. Будет завешивать все отражающие поверхности.', is_curable: true },
  { name: 'Акустикофобия', tier: 'A', tags: 'panic, mental, noise', weight: -1, description: 'Боязнь громких звуков. Взрывы или шум машин вызывают истерику.', is_curable: true },

  # --- Tier B (Социальные и бытовые страхи) ---
  { name: 'Петтофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь пукнуть при людях. Постоянное дикое напряжение в животе.', is_curable: true },
  { name: 'Децидофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь принимать решения. Никогда не сможет быть лидером.', is_curable: true },
  { name: 'Охлофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь толпы. Жить в тесном бункере с 8 людьми — мучение.', is_curable: true },
  { name: 'Андрофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь мужчин. Опасается половины населения бункера.', is_curable: true },
  { name: 'Гинофобия', tier: 'B', tags: 'social, mental', weight: -2, description: 'Боязнь женщин. Проблемы с общением и репродукцией.', is_curable: true },
  { name: 'Педофобия', tier: 'B', tags: 'social, mental', weight: -1, description: 'Боязнь детей. Не захочет участвовать в возрождении популяции.', is_curable: true },
  { name: 'Эротофобия', tier: 'B', tags: 'sexual, mental', weight: -1, description: 'Боязнь секса и наготы. Мешает созданию пар.', is_curable: true },
  { name: 'Аблютофобия', tier: 'B', tags: 'hygiene, mental', weight: -2, description: 'Боязнь мытья. Станет источником вони и инфекций.', is_curable: true },

  # --- Tier C (Тяжелые для бункера страхи) ---
  { name: 'Аблутофобия', tier: 'C', tags: 'panic, hygiene', weight: -2, description: 'Паническая боязнь умывания и водных процедур. Запах будет проблемой.', is_curable: true },
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
  { name: 'Акрофобия', tier: 'C', tags: 'panic, mental', weight: -1, description: 'Боязнь высоты. Бесполезен на смотровых вышках.', is_curable: true },
  { name: 'Иатрофобия', tier: 'C', tags: 'panic, mental, medical', weight: -2, description: 'Боязнь врачей. Не подпустит к себе медика даже при ранении.', is_curable: true },
  { name: 'Сцелерофобия', tier: 'C', tags: 'panic, mental, criminal', weight: -2, description: 'Боязнь плохих людей/грабителей. Подозревает всех в злом умысле.', is_curable: true },
  { name: 'Автофобия', tier: 'C', tags: 'panic, mental, isolation', weight: -2, description: 'Боязнь одиночества. Начнет истерику, если оставить его на посту одного.', is_curable: true }
]

phobias.each { |ph| Card.create!(**ph, category: 'phobia') }

puts "Создание хобби (расширенный список)..."
hobbies = [
  # --- Tier S (Критически полезные навыки) ---
  { name: 'Гидропоника', tier: 'S', tags: 'food, agriculture, science', weight: 3, description: 'Умеет выращивать растения без почвы, на питательных растворах.' },
  { name: 'Любительская радиосвязь', tier: 'S', tags: 'technical, communication', weight: 3, description: 'Сможет собрать рацию из мусора и выйти на связь с другими выжившими.' },
  { name: 'Охота и рыбалка', tier: 'S', tags: 'food, survival, weapon', weight: 3, description: 'Мастер добычи пропитания в дикой природе.' },
  { name: 'Робототехника', tier: 'S', tags: 'technical, repair', weight: 3, description: 'Собирает дронов и автоматизирует системы защиты.' },
  { name: 'Боевые искусства', tier: 'S', tags: 'security, physical', weight: 2, description: 'Черный пояс. Может нейтрализовать противника без оружия.' },

  # --- Tier A (Прикладные и медицинские навыки) ---
  { name: 'Холодное оружие', tier: 'A', tags: 'security, weapon', weight: 2, description: 'Коллекционирует и мастерски владеет ножами и топорами.' },
  { name: 'Дачник', tier: 'A', tags: 'food, agriculture', weight: 2, description: 'Знает, как выжать максимум урожая из шести соток.' },
  { name: 'Пиротехника', tier: 'A', tags: 'technical, explosive', weight: 2, description: 'Умеет создавать взрывчатку и сигнальные огни из бытовой химии.' },
  { name: 'Массаж и акупунктура', tier: 'A', tags: 'medical, health', weight: 1, description: 'Снимает боли и лечит зажимы без лекарств.' },
  { name: 'Пивоварение', tier: 'A', tags: 'food, social, medical', weight: 1, description: 'Спирт — лучший антисептик и валюта апокалипсиса.' },
  { name: 'Паркур', tier: 'A', tags: 'physical, exploration', weight: 1, description: 'Мастер перемещения по руинам и препятствиям.' },

  # --- Tier B (Социальные и умеренно полезные) ---
  { name: 'ЗОЖ', tier: 'B', tags: 'health, physical', weight: 1, description: 'Никогда не болеет и мотивирует всех делать зарядку.' },
  { name: 'Нетрадиционная медицина', tier: 'B', tags: 'medical, strange', weight: 0, description: 'Лечит прикладыванием подорожника и энергией космоса.' },
  { name: 'Разговоры по душам', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Прирожденный слушатель, может успокоить любого в истерике.' },
  { name: 'Медитация', tier: 'B', tags: 'mental, health', weight: 1, description: 'Сохраняет ледяное спокойствие даже когда все рушится.' },
  { name: 'Нетворкинг', tier: 'B', tags: 'social', weight: 1, description: 'Умеет договариваться и объединять даже враждующих людей.' },
  { name: 'Краеведение', tier: 'B', tags: 'exploration, history', weight: 1, description: 'Знает все тайные ходы и заброшенные склады в округе.' },
  { name: 'Настольные игры', tier: 'B', tags: 'social, mental', weight: 0, description: 'Знает правила сотен игр, не даст группе заскучать.' },
  { name: 'Спорт и танцы', tier: 'B', tags: 'physical, social', weight: 0, description: 'Хорошая координация и выносливость.' },

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
  { name: 'Стриптиз', tier: 'C', tags: 'physical, social', weight: -1, description: 'Умеет красиво раздеваться под музыку. Эффектно, но зачем?' }
]

hobbies.each { |hb| Card.create!(**hb, category: 'hobby') }

puts "Создание фактов (расширенный список)..."
facts = [
  # --- Tier S (Критически полезные или уникальные) ---
  { name: 'Нобелевский лауреат по биоинженерии', tier: 'S', tags: 'science, medical', weight: 4, description: 'Гений мирового уровня. Может спасти человечество.' },
  { name: 'Взломал базу данных ЦРУ', tier: 'S', tags: 'technical, security', weight: 3, description: 'Обладает доступом к секретной информации и навыками кибервойны.' },
  { name: 'Строил подобные бункеры', tier: 'S', tags: 'technical, building', weight: 3, description: 'Знает все слабые места и скрытые системы убежища.' },
  { name: 'Знает лично президента', tier: 'S', tags: 'social, authority', weight: 2, description: 'Имеет связи на самом высоком уровне (были полезны раньше).' },
  { name: 'Телепат', tier: 'S', tags: 'strange, mental', weight: 3, description: 'Утверждает, что слышит мысли других. Возможно, просто псих.' },
  { name: 'Понимает язык животных', tier: 'S', tags: 'strange, nature', weight: 2, description: 'Может договориться с крысами или дикими зверями снаружи.' },
  { name: 'Запустил IT-стартап', tier: 'S', tags: 'social, technical', weight: 2, description: 'Обладает миллионным состоянием (в прошлом) и навыками управления.' },

  # --- Tier A (Боевые и выживальческие навыки) ---
  { name: 'Вернулся из горячей точки', tier: 'A', tags: 'security, combat', weight: 2, description: 'Боевой опыт, умеет выживать под обстрелом.' },
  { name: 'Вырос в семье лесника', tier: 'A', tags: 'nature, survival', weight: 2, description: 'С детства знает, как выжить в лесу без ничего.' },
  { name: 'Выживал на необитаемом острове', tier: 'A', tags: 'survival', weight: 2, description: 'Опыт полной изоляции и добычи ресурсов из ничего.' },
  { name: 'Знает азбуку Морзе', tier: 'A', tags: 'communication, technical', weight: 1, description: 'Сможет передать сигнал, когда выйдет из строя радио.' },
  { name: 'Сделает алкоголь из чего угодно', tier: 'A', tags: 'food, alcohol', weight: 2, description: 'Мастер дистилляции. Валюта и антисептик всегда в наличии.' },
  { name: 'Владеет 5 языками', tier: 'A', tags: 'social, language', weight: 1, description: 'Незаменим при контактах с другими группами.' },

  # --- Tier B (Социальные особенности и странности) ---
  { name: 'Душа компании', tier: 'B', tags: 'social', weight: 2, description: 'Обладает гипнотической улыбкой, все ему доверяют.' },
  { name: 'Прошел 2-недельные курсы психолога', tier: 'B', tags: 'social, mental_health', weight: 1, description: 'Думает, что может лечить людей, но знает только азы.' },
  { name: 'Обладатель уникального сопрано', tier: 'B', tags: 'art, social', weight: 0, description: 'Потрясающий голос для поддержания духа.' },
  { name: 'Победитель Паралимпийских игр', tier: 'B', tags: 'physical, survival', weight: 1, description: 'Невероятная воля к жизни и физическая подготовка.' },
  { name: 'Читал все книги Лавкрафта', tier: 'B', tags: 'strange', weight: 0, description: 'Готов к встрече с любыми ужасами апокалипсиса.' },
  { name: 'Продал почку', tier: 'B', tags: 'physical', weight: -1, description: 'Уже наполовину "разобран", но имеет опыт выживания после операций.' },

  # --- Tier C (Негативные факты, балласт или опасные роли) ---
  { name: 'Маньяк-убийца', tier: 'C', tags: 'danger, criminal', weight: -4, description: 'Скрытая угроза. Будет убивать выживших по одному.' },
  { name: 'Психопат', tier: 'C', tags: 'danger, mental', weight: -3, description: 'Полное отсутствие эмпатии и непредсказуемое поведение.' },
  { name: 'Только из очага эпидемии', tier: 'C', tags: 'danger, health', weight: -3, description: 'Возможно, он уже заражен и принесет смерть в бункер.' },
  { name: 'Наркодилер', tier: 'C', tags: 'criminal, social', weight: -2, description: 'Умеет находить подход к людям, но приносит только проблемы.' },
  { name: 'Состоял в секте', tier: 'C', tags: 'social, mental', weight: -1, description: 'Легко поддается чужому влиянию или сам начнет проповедовать.' },
  { name: 'Бродяжничал 2 года', tier: 'C', tags: 'social, survival', weight: 1, description: 'Привык к грязи и лишениям, неприхотлив.' },
  { name: 'Держал 40 кошек дома', tier: 'C', tags: 'strange', weight: -1, description: 'Странный одиночка, привыкший к специфическому обществу.' },

  # --- Мелкие недостатки и черты характера ---
  { name: 'Безотказный', tier: 'C', tags: 'social', weight: 1, description: 'Всегда делает то, что просят. Идеальный исполнитель.' },
  { name: 'Храпит', tier: 'C', tags: 'annoying', weight: -1, description: 'В бункере никто не сможет спать из-за него.' },
  { name: 'Грязно ругается', tier: 'C', tags: 'social', weight: -1, description: 'Раздражает окружающих своим лексиконом.' },
  { name: 'Зануда', tier: 'C', tags: 'social', weight: -1, description: 'Может довести до депрессии своими лекциями.' },
  { name: 'Нытик', tier: 'C', tags: 'social', weight: -2, description: 'Постоянно жалуется и деморализует группу.' },
  { name: 'Писается по ночам', tier: 'C', tags: 'hygiene', weight: -2, description: 'Проблема гигиены и дефицита чистого белья.' },
  { name: 'Подходит и дышит сзади', tier: 'C', tags: 'annoying, strange', weight: -1, description: 'Крайне пугающая и раздражающая привычка.' },
  { name: 'Тормоз', tier: 'C', tags: 'physical', weight: -2, description: 'Очень медленно соображает и реагирует.' },
  { name: 'Врет и преувеличивает', tier: 'C', tags: 'social', weight: -1, description: 'Никогда нельзя знать наверняка, правду ли он говорит.' }
]

facts.each { |f| Card.create!(**f, category: 'fact') }

puts "Успешно! База наполнена: #{Card.count} карт."

puts "Создание катастроф..."
Catastrophe.destroy_all

catastrophes = [
  { name: 'Всемирный потоп', description: 'Гравитационная аномалия приводит к расширению объема воды и затоплению всей поверхности суши. Выйдя из бункера, вам предстоит построить плавучую станцию и добывать пропитание на воде.' },
  { name: 'Восстание роботов', description: 'Сперва робот Fedor захватил соцсети, а затем все электронные устройства объединились против людей. Пылесосы атакуют, телефоны прожаривают мозги. Вам предстоит объявить войну гаджетам.' },
  { name: 'Динозавры', description: 'Ученым удалось воскресить динозавров, но ситуация вышла из-под контроля. Стаи монстров сметают всё на пути. Вам предстоит обеспечить свое пропитание и не стать едой для новых хозяев мира.' },
  { name: 'Духи и призраки', description: 'На Земле воцарилась вечная жизнь. Люди увлеклись мистикой, и призраки обрели реальную силу, проникая в головы людей. Вам нужно вычислить культурный объект, дающий им силу.' },
  { name: 'Власть алгоритмов', description: 'ИИ подчинил человечество. Сперва люди слушались автонавигатора, а теперь ИИ диктует, кем работать и когда умирать. Вам предстоит взломать программный код ИИ.' },
  { name: 'Зомби-апокалипсис', description: 'Неизвестный вирус превращает людей в зомби. После выхода из бункера вам нужно будет постоянно отбиваться от атак зомби и найти способ защититься от вируса.' },
  { name: 'Инопланетяне', description: 'Чужая цивилизация временно парализует человечество, чтобы принять решение о ценности нашей цивилизации. Вам нужно выйти на контакт и убедить их в ценности культуры.' },
  { name: 'Инф. война', description: 'Нейронные сети начали генерировать заголовки новостей, которые сводили людей с ума. Вам нужно добраться до новостных центров и перенастроить нейронные сети.' },
  { name: 'Котопокалипсис', description: 'Эксперименты с наполнителями привели к тому, что коты научились мурчать на частотах, лишающих людей воли. Вам нужно победить котозависимость.' },
  { name: 'Мутанты', description: 'Поедание ГМО привело к страшным последствиям. Люди считают себя супергероями и сходят с ума. Вам предстоит вырастить чистые продукты и вылечить мутантов.' },
  { name: 'Метеорит', description: 'Крупный метеорит приближается к Земле. Столкновение приведет к смене климата и гибели флоры. Вам предстоит обеспечить пропитание в условиях вечной зимы.' },
  { name: 'Пандемия', description: 'Смертельный вирус вышел из-под контроля. После выхода вас встретят мутировавшие животные и люди. Вам придется разрабатывать вакцину от вируса.' },
  { name: 'Русский эпос', description: 'Щуку из сказки "заклинило", она исполняет желания каждую минуту. Люди в небе, люди под землей. Нужно найти "культурный антидот", чтобы снять проклятие.' },
  { name: 'Ктулху', description: 'Распространение настольных игр привело к появлению фанатиков, призвавших Ктулху. Человечество массово теряет рассудок. Вам нужно запечатать мистические врата.' },
  { name: 'Потеря эстетики', description: 'Люди утратили чувство красоты и деградируют в диких животных. Цивилизация рухнула. Вам предстоит вернуть в мир культуру и спасти человечество.' },
  { name: 'Страдающий Коля', description: 'Авария в ядерном центре привела к разлому времени. Средневековый эксгибиционист Коля пугает людей нашего времени. Нужно вернуть Колю в его средневековье.' },
  { name: 'Суицидальная фауна', description: 'Аномальный виток эволюции заставляет растения и деревья сводить людей с ума и заставлять совершать самоубийства. Нужно найти эпицентр аномалии.' },
  { name: 'Супервулканы', description: 'Активизируются супервулканы. Ландшафт и климат резко меняются. Вам предстоит выжить, разработав систему предсказания извержений.' },
  { name: 'Ядерная война', description: 'Масштабный ядерный конфликт. Радиоактивная пыль окутает планету, наступит долгая ядерная зима. Нужно обустроить убежище и начать жизнь заново.' },
  { name: 'Химическая война', description: 'Применение химоружия нарушило баланс. Почвы и воды отравлены. Вам пригодятся ученые и инженеры для обустройства ферм.' }
]

catastrophes.each { |c| Catastrophe.create!(c) }

puts "Создание угроз..."
Threat.destroy_all

threats = [
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
  { name: 'Стресс-вирус', description: 'Вспышка смертельного вируса, развивающегося только на фоне стресса. Будут полезны медицинские навыки / снаряжение, а также любые способы контролировать стресс. Не нервничаем, всё хорошо, мы все равно все умрем...' }
]

threats.each { |t| Threat.create!(t) }

puts "Создание особенностей бункера..."
BunkerFeature.destroy_all

features = [
  { name: 'Силовое поле', description: 'Переносной генератор защитного силового поля.' },
  { name: 'Подвал', description: 'Бункер строили заключенные. Жуткий запах привел вас в подвал, где вы нашли их останки. А заодно их инструменты и оружие охранников.' },
  { name: 'Радио', description: 'По внутреннему радио классическую музыку постоянно сменяет Киркоров. Можно потренировать стрессоустойчивость.' },
  { name: 'Уклон 45°', description: 'В результате тектонических сдвигов бункер слегка наклонен. Где-то на 45 градусов.' },
  { name: 'Некрономикон', description: 'Огромный древний фолиант на неизвестном языке с мистическими иллюстрациями. Похоже на гримуар с заклинаниями и анатомическую энциклопедию.' },
  { name: 'Робот-полиграф', description: 'Автономный робот-переводчик с функцией полиграфа. Пригодится для сложных переговоров.' },
  { name: 'Шкаф с настолками', description: 'Шкаф с настольными играми! Погодите-ка, но тут только всевозможные виды Монополии... Хорошо, что нам некуда спешить.' },
  { name: 'Учебник', description: 'Учебное пособие «Как убедить зомби не жрать ваш мозг».' },
  { name: 'Хим. лаборатория', description: 'Хим. лаборатория и реактивы. Можно устроить гидропоническую ферму.' },
  { name: 'Мастерская', description: 'Мастерская с инструментами.' },
  { name: 'Кофе', description: 'Кофемолка и запас ароматного обжаренного зернового кофе. Напоминание о нормальной жизни до всего этого безумия...' },
  { name: 'Крысы', description: 'Похоже, что в бункере обитают полчища крыс или каких-то грызунов. В критической ситуации или мы для них еда, или они для нас.' },
  { name: 'Книга о еде', description: 'Книга «О вкусной и здоровой пище» как предмете искусства и культуры. С ценными главами о том, как добывать и готовить вкусную еду даже в самых экстремальных условиях.' },
  { name: 'Катакомбы', description: 'Из подвала есть выход в естественный грот с подземной рекой. Судя по запаху, по реке можно попасть в разваленную систему городской канализации и выйти куда угодно.' },
  { name: 'Керосиновые лампы', description: 'С перебоями работает электрическое освещение. Но есть керосиновые лампы и запас топлива. Коктейли Молотова пригодятся для защиты.' },
  { name: 'Мед. лаборатория', description: 'Медицинская лаборатория с операционной.' },
  { name: 'Медиатека', description: 'Есть автономная медиатека, новшей только порнофильмы — кажется, за всю историю кинематографа.' },
  { name: 'Мусор', description: 'Дырявые матрасы и тряпки, брошенный строительный мусор. Среди мусора — старинные газеты, аж 2020-го года!' },
  { name: 'Жертвенник', description: 'Спальных мест ровно по числу людей. Одно из них стоит обособленно и похоже на жертвенный алтарь.' },
  { name: 'Гречка', description: 'Из запасов продовольствия только гречка. Зато очень много, похоже на двойной запас.' },
  { name: 'Динамо-машина', description: 'Резервный электрогенератор с велоприводом и куча металлолома.' },
  { name: 'Голосовое управление', description: 'Бункером управляет ИИ с голосовым интерфейсом. Команды он понимает с пятой попытки.' },
  { name: 'Вместе на 10 лет', description: 'Этот бункер откроется и выпустит вас только через 10 лет. Запас еды соответствующий. Но за это время наверняка случится не одна неприятность.' },
  { name: 'Гипномодуль', description: 'Модуль гипно-телепатической коммуникации и детектор паранормальных полей.' },
  { name: 'Загадочный журнал', description: 'Странный старый журнал, в котором имена всех из вашей команды, кто стоит у бункера. Рядом даты 33-летней давности... и точное описание всего, что с вами происходит.' },
  { name: 'Записи контрабандиста', description: 'Библиотека контрабандиста. Кто только не прятался в этом бункере. Детально описаны все ценные предметы искусства, которые есть в округе, с маршрутами вывоза мимо полиции.' },
  { name: 'Инструкция к микроволновке', description: 'В бункере нет туалетной бумаги. Зато вы нашли инструкцию по перепрограммированию микроволновки на 7174 языках. Можно и программированию научиться, и языки выучить.' },
  { name: 'Видео со спутника', description: 'На стены проецируется релаксационное видео съемок со спутника. Красиво и умиротворяюще. Ого, да ведь это окрестности бункера! И детализация отличная.' },
  { name: 'R2D2', description: 'Робот-психолог. Молча слушает и кивает, иногда что-то пиликает. Пригодится на запчасти, если что.' },
  { name: 'Аптечки', description: 'У входа есть аптечки, резиновые перчатки, маски и огнетушитель.' }
]

features.each { |f| BunkerFeature.create!(f) }
