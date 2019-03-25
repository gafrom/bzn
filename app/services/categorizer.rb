class Categorizer
  TITLES_SCHEDULE = {
    '(куртка|пуховик|бомбер|тренч|пальто|накидк|плащ|шуба|ветровка|парка|жилет|фр[еэ]нч|пиджак|болеро|портупея|жакет)' => 2, # Верхняя одежда
    '(платье|сарафан|платьице|платья)' => 3, # Платья
    '(костюм.+спортивн|спортивн.+костюм)' => 9, # Спортивные костюмы
    '(пижама|халат)' => 12, # Одежда для дома
    '(костюм|комплект)' => 4, # Костюмы и комплекты
    '(пуловер|толстовка|джемпер|свитер|свитшот|туника|кардиган|худи|батник|кофт|рубашка|блуз|футболка|майка|сорочка|боди|водолазка|\Aтоп|\Aкроп\-топ)' => 5, # Футболки,блузы,свитера
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
end
