class Colorizer
  SPLIT_CHARS = /([\,\-\;\.\+\/])/
  ADJ_SUF = /(ый|ий|ой|ая|яя|ое|ее|ом|ем|ые|ие|ым)\Z/
  OE_SUF = /[ое]\Z/
  SPACE = ' '.freeze
  SPL = /(морская\sволна|слоновая\sкость|крем[\-\s]брюле|пыльная\sроза|чайная\sроза)|\s/x
  DISREGARD = %w[\Aт\Z \Aтемн \Aсв\z \Aсветл \Aмокр \Aярк \Aбледн \Aспел \Aтепл \Aбархат
                 \Aна\Z \Aс\Z \Ac\Z \Aв\Z \Aабстрак \Aглубок \Aклассическ \Aклеверн
                 \Aмелк \Aнеж \Aотделка \Aприглушен \Aтонк \Aтропическ \Aфойл
                 \Aцвет\Z \Aширок \A&quot\Z \Aкрупн \Aгусин \Aфон \Aдухи \Aузор
                 \Aромб \Aкреп\Z \Aоттенок \Aпод\Z \Aверх \Aниз \Aперламутр \Aхищн
                 \Aи\Z \Aразводы\Z \Aпояс\Z \Aзаг\Z \Aлюрекс]
  SCHEDULE = {
    'мультиколлор'    =>  [3], # Мультиколор
    'мультиколор'     =>  [3],
    'разноцветн'      =>  [3],
    'акварель'        =>  [3],
    'радуга'          =>  [3],
    'черн'            =>  [4], # Черный
    'принт'           =>  [5], # Принт (рисунок)
    'бел'             =>  [6], # Белый
    'сер'             =>  [7], # Серый
    'бирюзов'         =>  [8], # Бирюзовый
    'зелен'           =>  [9], # Зеленый
    'салатов'         =>  [9], # Зеленый
    'изумрудн'        =>  [9], # Зеленый
    'розов'           => [10], # Розовый
    'красн'           => [11], # Красный
    'бежев'           => [12], # Бежевый
    'беж'             => [12],
    'желт'            => [13], # Желтый
    'коричнев'        => [14], # Коричневый
    'голуб'           => [15], # Голубой
    'син'             => [16], # Синий
    'фиолетов'        => [17], # Фиолетовый
    'фиолет'          => [17],
    'фиол'            => [17],
    'сиренев'         => [17], # Фиолетовый
    'золотист'        => [18], # Золотистый
    'золот'           => [18], # Золотистый
    'серебрист'       => [19], # Серебристый
    'серебрян'        => [19], # Серебристый
    'серебро'         => [19], # Серебристый
    'оранжев'         => [20], # Оранжевый
    'оранж'           => [20],
    'персиков'        => [12, 13],
    'кораллов'        => [10, 11],
    'коралл'          => [10, 11],
    'бордов'          => [11],
    'фуксия'          => [10, 11],
    'мятн'            => [9],
    'морская волна'   => [8, 15],
    'молочн'          => [6, 12],
    'молок'           => [6, 12],
    'терракот'        => [11, 20],
    'горчичн'         => [13, 20],
    'малинов'         => [10, 11],
    'песок'           => [7, 12],
    'слоновая кость'  => [6, 12],
    'кофе с молоком'  => [12, 14],
    'крем брюле'      => [12, 13, 14],
    'в полоску'       => [5],
    'абрикосов'    => [12, 13, 20],
    'ал'           => [11],
    'ангора'       => [7, 12],
    'апельсинов'   => [20],
    'бабочки'      => [5],
    'баклажанов'   => [17],
    'бантики'      => [5],
    'бананы'       => [5],
    'бирюза'       => [8],
    'бордо'        => [11, 14],
    'брусничн'     => [11],
    'буквы'        => [5],
    'ванильн'      => [6, 12],
    'васильков'    => [16],
    'васельков'    => [16],
    'велосипеды'   => [5],
    'велосипед'    => [5],
    'вензель'      => [5],
    'вензеля'      => [5],
    'веточки'      => [5],
    'винн'         => [11, 14],
    'вишнев'       => [11, 17],
    'вишня'        => [11, 17],
    'вишни'        => [11, 17],
    'геометрия'    => [5],
    'графичиск'    => [5],
    'гербы'        => [5],
    'гжель'        => [5],
    'глициния'     => [10, 17],
    'горох'        => [5],
    'горохи'       => [5],
    'горошек'      => [5],
    'графит'       => [7],
    'графитов'     => [7],
    'джинс'        => [15, 16],
    'джинсов'      => [15, 16],
    'джинсово'     => [15, 16],
    'дымка'        => [7],
    'дымчато'      => [7],
    'ежевика'      => [4, 17],
    'ежевичн'      => [4, 17],
    'жемчуг'       => [6, 12, 19],
    'жемчужн'      => [6, 12, 19],
    'журавли'      => [5],
    'зайцы'        => [5],
    'звезды'       => [5],
    'звездочка'    => [5],
    'звездочки'    => [5],
    'зебра'        => [4, 6],
    'зелень'       => [9],
    'зигзаги'      => [5],
    'зигзаг'       => [5],
    'зиг'          => [5],
    'змею'         => [5],
    'индиго'       => [16, 17],
    'ирисы'        => [16, 17],
    'какао'        => [14],
    'капучино'     => [12, 14],
    'карамельн'    => [12, 13],
    'квадрат'      => [5],
    'кирпич'       => [11],
    'кирпичн'      => [11],
    'кислотн'      => [9, 13],
    'клевер'       => [5],
    'клетка'       => [5],
    'ключи'        => [5],
    'кокосов'      => [6, 12],
    'колокольчики' => [5],
    'короны'       => [5],
    'кофе'         => [14],
    'кофейн'       => [14],
    'кофейно'      => [14],
    'коричнеро'    => [14],
    'кошки'        => [5],
    'красным'      => [11],
    'кремов'       => [6, 12],
    'кэмел'        => [12, 14],
    'лавандов'     => [16, 17],
    'лагуна'       => [16],
    'лазурн'       => [8, 15, 16],
    'лазурно'      => [8],
    'лайм'         => [9, 13],
    'ландыш'       => [5],
    'лапки'        => [5],
    'лапка'        => [5],
    'леопард'      => [4, 13],
    'лепестков'    => [12],
    'лепесток'     => [5],
    'лилов'        => [10, 17],
    'лилии'        => [5],
    'листья'       => [5],
    'лист'         => [5],
    'листочки'     => [5],
    'лимонн'       => [13],
    'лососев'      => [11],
    'лошади'       => [5],
    'лошадки'      => [5],
    'люди'         => [5],
    'мак'          => [5],
    'малахит'      => [8, 9],
    'малахитов'    => [8, 9],
    'маренго'      => [7],
    'марсала'      => [11, 14, 10],
    'меланж'       => [7],
    'ментолов'     => [8],
    'ментол'       => [8],
    'микки'        => [5],
    'милитари'     => [9],
    'мокко'        => [14],
    'монеты'       => [5],
    'мозаика'      => [5],
    'морковн'      => [11, 20],
    'мята'         => [8, 9],
    'небо'         => [6, 15],
    'небесно'      => [6, 15],
    'облако'       => [5],
    'огурцы'       => [5],
    'одуванчики'   => [5],
    'оливков'      => [9],
    'орех'         => [14],
    'орехов'       => [14],
    'орнамент'     => [5],
    'охра'         => [13, 20],
    'очки'         => [5],
    'персик'       => [12, 13, 20],
    'перья'        => [5],
    'песочн'       => [12, 13],
    'пейсли'       => [5],
    'пион'         => [5],
    'пионы'        => [5],
    'пламенн'      => [11],
    'полоска'      => [5],
    'полоса'       => [5],
    'полосы'       => [5],
    'полоски'      => [5],
    'полынь'       => [8, 9],
    'попугаи'      => [5],
    'птицы'        => [5],
    'пудра'        => [10, 12],
    'пудров'       => [10, 12],
    'пыльн'        => [7],
    'пыльно'       => [7],
    'пчела'        => [5],
    'рисунок'      => [5],
    'розы'         => [5],
    'роза'         => [5],
    'ромашки'      => [5],
    'ромашка'      => [5],
    'ромбы'        => [5],
    'рыж'          => [11, 20],
    'сакура'       => [5],
    'свекольн'     => [17],
    'сердца'       => [5],
    'сердечки'     => [5],
    'сердечко'     => [5],
    'сливов'       => [10, 17],
    'слоны'        => [5],
    'совы'         => [5],
    'стальн'       => [7, 19],
    'стрекозы'     => [5],
    'стрекоза'     => [5],
    'тауп'         => [12, 14],
    'терракотов'   => [11, 14, 20],
    'текст'        => [5],
    'точки'        => [5],
    'травян'       => [9],
    'треугольник'  => [5],
    'треугольники' => [5],
    'туфли'        => [5],
    'тюльпаны'     => [5],
    'узоры'        => [5],
    'ультрамарин'  => [16],
    'фиалков'      => [10, 17],
    'фисташков'    => [9],
    'фламинго'     => [11],
    'фотопечать'   => [5],
    'хаки'         => [9],
    'хвойн'        => [9],
    'цветн'        => [3],
    'цветочн'      => [3],
    'цветы'        => [5],
    'цветок'       => [5],
    'цветочки'     => [5],
    'цепи'         => [5],
    'черничн'      => [16, 17],
    'шампанск'     => [12],
    'шашечки'      => [5],
    'шоколадн'     => [14],
    'шоколад'      => [14],
    'штрихи'       => [5],
    'электрик'     => [16],
    'ягодн'        => [10, 11, 17],
    'якоря'        => [5],
    'круги'        => [5],
    'кружево'      => [5],
    'пыльная роза' => [11, 12],
    'чайная роза'  => [11, 12],
    'гобелен'      => [5],
    'пюсов'        => [11, 14], # бурый или нежно алый
    'иссиня'       => [16] # Синий
  }

  def initialize
    @disregarding_pattern = /(#{DISREGARD.join('|')})/
  end

  def ids(color_string)
    colors = split prepared color_string

    colors.inject([]) do |result, color|
      next result if disregard? color
      result += fetch stemmed color
    end.compact.uniq
  end

  private

  def disregard?(color)
    color =~ @disregarding_pattern
  end

  def stemmed(string)
    string.sub(ADJ_SUF, '')
  end

  def prepared(string)
    string.downcase.gsub('ё', 'е').gsub(' ', ' ').gsub('лимоный', 'лимонный')
  end

  def split(string)
    string.gsub('роз.', 'розовый ')
          .gsub('тем-', 'темно ')
          .gsub(SPLIT_CHARS, SPACE)
          .squeeze(SPACE).strip.split(SPL)
          .reject &:empty?
  end

  def fetch(stem)
    SCHEDULE[stem] || SCHEDULE.fetch(stem.sub OE_SUF, '')
  rescue KeyError
    msg = "[PARSING ERROR] Cannot infer color from stem '#{stem}'"
    raise NotImplementedError, msg
  end
end
