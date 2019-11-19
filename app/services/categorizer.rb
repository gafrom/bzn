class Categorizer
  TITLES_SCHEDULE = {
    '(куртка|пуховик|бомбер|тренч|пальто|накидк|плащ|шуба|ветровка|парка|жилет|фр[еэ]нч|пиджак|болеро|портупея|жакет)' => 2, # Верхняя одежда
    '(платье|сарафан|платьице|платья)' => 3, # Платья
    '(костюм.+спортивн|спортивн.+костюм)' => 9, # Спортивные костюмы
    '(пижама|халат)' => 12, # Одежда для дома
    '(костюм|комплект)' => 4, # Костюмы и комплекты
    '(лонгслив|пуловер|толстовка|джемпер|свитер|свитшот|туника|кардиган|худи|батник|кофт|рубашка|блуз|футболка|майка|сорочка|боди|водолазка|\Aтоп|\Aкроп\-топ)' => 5, # Футболки,блузы,свитера
    'комбинезон' => 6, # Комбинезоны
    '(брюки|шорты|легинсы|бриджи|брижди|капри|лосины|леггинсы|шортики|штаны|джинсы)' => 7, # Брюки, леггинсы, шорты
    'юбка' => 8, # Юбки
    '(купальник|туника.+для.+пляжа|пляжная.+туника)' => 10, # Купальники, пляжные туники
    '(сумк|рюкзак|клатч|кошел[её]к|косметичка|сумочка)' => 11, # Сумки, клатчи, кошельки
    '(перчатки|шарф|платок|шапка|шляпка|кепка|повязка\sна\sголову|снуд|палантин)' => 13, # Перчатки, шарфы, шапки
    '(бижутерия|нить|бусы|браслет|серьги|колье|подвес|кольц|часы|очки|ремень|кушак|брошь|брелоки|пояс|колготки)' => 15 # Аксессуары
  }

  def initialize(remote_id: nil, title: nil)
    @remote_id = remote_id
    @title = title
  end

  def category_id
    @category_id ||= begin
      fetched = case @remote_id
                when nil then nil
                when Array
                  @remote_id.each do |remote_id|
                    id = self.class::SCHEDULE[remote_id.to_i]
                    break id if id
                  end
                  nil
                else
                  self.class::SCHEDULE[@remote_id.to_i]
                end
      fetched || id_from_title
    end
  end

  def category
    @category ||= Category.find category_id
  end

  def from_title
    @category ||= Category.find id_from_title
  end

  def id_from_title
    TITLES_SCHEDULE.each do |pattern, id|
      return id if /#{pattern}/i =~ @title
    end

    raise NotImplementedError, "[PARSING ERROR] cannot infer category from title: '#{@title}'"
  end

  def self.safe_id_from_title(title)
    TITLES_SCHEDULE.each do |pattern, id|
      return id if /#{pattern}/i =~ title
    end

    nil
  end
end


# => 1, # Одежда
#    => 2, # Верхняя одежда
#    => 3, # Платья
#    => 4, # Костюмы и комплекты
#    => 5, # Футболки, блузы, свитера
#    => 6, # Комбинезоны
#    => 7, # Брюки, леггинсы, шорты
#    => 8, # Юбки
#    => 9, # Спортивные костюмы
#    => 10, # Купальники, пляжные туники
#    => 11, # Сумки, клатчи, кошельки
#    => 12, # Одежда для дома
#    => 13, # Перчатки, шарфы, шапки
#      => 83, # Перчатки
#      => 84, # Шарфы
#      => 85, # Платки
#      => 86, # Шапки
#      => 87, # Шляпки
#      => 88, # Комплекты
#      => 156, # Кепки
#      => 157, # Повязки на голову
#    => 14, # Обувь
#      => 89, # Туфли
#      => 90, # Сапоги
#      => 91, # Сникерсы
#      => 92, # Ботинки
#      => 93, # Лоферы
#      => 94, # Угги
#      => 158, # Сандалии
#      => 159, # Босоножки
#      => 160, # Слипоны
#    => 15, # Аксессуары
#      => 95, # Бижутерия
#        => 119, # Браслеты
#        => 120, # Колье
#        => 121, # Серьги
#        => 122, # Кольца
#        => 123, # Комплекты
#      => 96, # Часы
#        => 124, # Металлические
#        => 125, # Керамические
#        => 126, # Каучуковые
#        => 127, # Кожаный ремешок
#        => 128, # Текстильный ремешек
#      => 97, # Очки
#        => 129, # Пластиковая оправа
#        => 130, # Металлическая оправа
#      => 98, # Брелоки
#      => 99, # Ремни
#      => 155, # Носки, колготки
#    => 16, # Детская одежда
#    => 17, # Мужская одежда
#    => 131, # Новинки
#    => 132, # Звёздные коллекции
#      => 133, # Айза Долматова
#      => 134, # Алёна Шишкова
#      => 135, # Ксения Бородина
#      => 136, # Ольга Бузова
#      => 138, # Анастасия Решетова
#      => 143, # Светлана Пермякова
#      => 152, # Анна Хилькевич
#    => 137, # ТОП продаж
#    => 144, # Одежда для беременных
#      => 145, # Платья и сарафаны
#      => 146, # Блузы джемпера туники
#      => 147, # Брюки леггинсы
#      => 148, # Спортивная одежда
#      => 149, # Верхняя одежда (Беременные)
#    => 151, # Нижнее бельё





# '(сапоги)'                                                  => 39, # Обувь
# '(носки|колготки|колкогтки)'                                => 38, # Носки, колготки
# '(купальн|пляж)'                                            => 37, # Купальники и пляжные туники
# '(джемпер|кардиган|свитер|кофта|толстовка|батник|кофточка)'  =>  4, # Джемперы, кофты и кардиганы

# '(пижама|халат|пеньюар)'                                    =>  9, # Одежда для дома

# # 'толстовка'                                               => 14, # Толстовки
# '(водолазка|гольфик)'                                       => 16, # Водолазки
# '(джинсы|скини|джеггинсы)'                                  =>  7, # Джинсы


# '(жилет|френч)'                                             => 13, # Жилеты
# 'худи'                                                      => 15, # Худи
# 'свитшот'                                                   => 17, # Свитшоты
# '(шампунь|бальзам|обруч)'                                   => 19, # Аксессуары для волос
# '(бижутерия|нить|бусы|браслет|серьги|колье|подвеска|кольц)' => 20, # Бижутерия
# '(шапка|шляпа|панама|бейсболка|кепка|ушки|наушники)'        => 21, # Головные уборы
# 'бандана'                                                   => 22, # Банданы
# '(сумк|рюкзак|клатч|сумочк)'                                => 23, # Сумки и рюкзаки
# '(ремень|пояс)'                                             => 24, # Ремни и пояса
# '(платок|шарф|палантин|воротник|повязка)'                   => 25, # Платки и шарфы
# '(очки|авиаторы)'                                           => 26, # Очки и футляры
# 'кошел(ё|е)к'                                               => 27, # Кошельки и кредитницы
# 'зонт'                                                      => 28, # Зонты
# '(обложка|ключница|брелок|косметичка)'                      => 29, # Обложки, ключницы, брелки
# '(часы|ремешок)'                                            => 30, # Часы и ремешки
# '(перчатки|варежки)'                                        => 31, # Перчатки и варежки
# 'носовой\sплаток'                                           => 32, # Носовые платки
# '(зеркальце|зеркало)'                                       => 33, # Зеркальца
# '(галстук|бабочка)'                                         => 34, # Галстуки и бабочки
# '(футболка|топ|майка|боди)'                                 =>  1, # Футболки и топы
# 'маска\sдля\sсна'                                           => 35  # Маски для сна
