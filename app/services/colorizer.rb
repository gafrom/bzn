class Colorizer
  ADJ_SUF = /(ый|ий|ой|ая|яя|ое|ее)\Z/
  OE_SUF  = /[ое]\Z/
  SPACE = ' '.freeze
  SPL = /(морская\sволна)|\s/

#    slugs << 'print' if /(print|melanzh|ornament|uzor|kletka|cvety|goroh|vyshivka|ljurex|poloska|multiko|stegann|cvetnoj|raznocvet|applikaciya)/ =~ color_slug
#     slugs << 'rozovyj' if /(rozov|lilov|bronzov|roza|pjusovyj|fuxi|koral|korllov|barbi|losos)/ =~ color_slug
#     slugs << 'sinij' if /(sin|jelektrik|vasilkovyj|chernichnyj|minij|grifeln|cinij|ultramarin|sapfir)/ =~ color_slug
#     slugs << 'fioletovyj' if /(fioletov|baklazhanovyj|slivov|fiolet|purpurn)/ =~ color_slug
#     slugs << 'sirenevyj' if /(sirenev|lavand|gliciniya)/ =~ color_slug
#     slugs << 'goluboj' if /(golub|bijuzovyj|morskaya-volna|birjuz|lazurnyj|dzhins|morskoj-volny|goloboj)/ =~ color_slug
#     slugs << 'korichnevyj' if /(korichn|kofejnyj|kakao|shokolad|kapuchin|orehov|kofe|kokao)/ =~ color_slug
#     slugs << 'zelenyj' if /(zelen|bolotn|fistashkov|olivk|izurud|izumrud|haki|nefrit|hakki|butylka|malahit)/ =~ color_slug
#     slugs << 'myatnyj' if /(myatn|salotov|lajm|mentol|salat|myata|mytnyj)/ =~ color_slug
#     slugs << 'bezhevyj' if /(bezh|kremov|pudr|slonov|abrikos|frezov|shampan|vanil)/ =~ color_slug
#     slugs << 'molochnyj' if /(molochn|zhemchuzhn|moloko)/ =~ color_slug
#     slugs << 'seryj' if /(ser|tabachn|grafit|stalnoj|metal|grifeln)/ =~ color_slug
#     slugs << 'chernyj' if /(chern|chjornyj)/ =~ color_slug
#     slugs << 'krasnyj' if /(krasn|vinnyj|yagodn|morkovn|vishnev|malinov|marsala|terrakot|granatov|bordov|kirpich|brusnichn|alyj|bordo|marsalov|malina)/ =~ color_slug
#     slugs << 'zheltyj' if /(zhelt|limonn|gorchic|pesochn|zolot|gorichichnyj|gorichica|zhjoltyj|mednyj|zhelyj)/ =~ color_slug
#     slugs << 'belyj' if /bel/ =~ color_slug
#     slugs << 'oranzhevyj' if /(oranzh|persik|abrikosov)/ =~ color_slug

  SCHEDULE = {
    'мультиколлор'    =>  [3], # Мультиколор
    'мультиколор'     =>  [3], # Мультиколор
    'разноцветн'      =>  [3], # Мультиколор
    'черн'            =>  [4], # Черный
    'бел'             =>  [6], # Белый
    'сер'             =>  [7], # Серый
    'бирюзов'         =>  [8], # Бирюзовый
    'зелен'           =>  [9], # Зеленый
    'салатов'         =>  [9], # Зеленый
    'изумрудн'        =>  [9], # Зеленый
    'розов'           => [10], # Розовый
    'красн'           => [11], # Красный
    'бежев'           => [12], # Бежевый
    'желт'            => [13], # Желтый
    'коричнев'        => [14], # Коричневый
    'голуб'           => [15], # Голубой
    'син'             => [16], # Синий
    'фиолетов'        => [17], # Фиолетовый
    'сиренев'         => [17], # Фиолетовый
    'золотист'        => [18], # Золотистый
    'золот'           => [18], # Золотистый
    'серебрист'       => [19], # Серебристый
    'серебрян'        => [19], # Серебристый
    'оранжев'         => [20], # Оранжевый
    'персиков'        => [12, 13],
    'кораллов'        => [10, 11],
    'бордов'          => [11],
    'фуксия'          => [10, 11],
    'мятн'            => [9],
    'морская волна'   => [8, 15],
    'молочн'          => [6, 12],
    'терракот'        => [11, 20],
    'горчичн'         => [13, 20],
    'малинов'         => [10, 11]
  }

  def ids(color_string)
    colors = split prepared color_string
    colors.inject([]) do |result, color|
      result += fetch stemmed color
    end.uniq
  end

  private

  def stemmed(string)
    string.sub(ADJ_SUF, '').sub(OE_SUF, '')
  end

  def prepared(string)
    string.downcase.gsub('ё', 'е')
  end

  def split(string)
    string.gsub(/[\,\-]/i, SPACE).squeeze(SPACE).strip.split(SPL).reject &:empty?
  end

  def fetch(stem)
    SCHEDULE.fetch stem
  rescue KeyError
    msg = "[PARSING ERROR] Cannot infer color from stem '#{stem}'"
    raise NotImplementedError, msg
  end
end
