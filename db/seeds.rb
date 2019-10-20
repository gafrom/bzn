puts 'Creating root category ...'
cat_title = 'Одежда'
cat = Category.find_or_initialize_by title: cat_title
done = cat.new_record? ? 'Created' : 'Already exists'
cat.save
puts "#{done} category id #{cat.id} => #{cat_title}"

puts 'Creating some categories ...'
categories = ["Верхняя одежда", "Платья", "Костюмы и комплекты", "Футболки, блузы, свитера", "Комбинезоны", "Брюки, леггинсы, шорты", "Юбки", "Спортивные костюмы", "Купальники, пляжные туники", "Сумки, клатчи, кошельки", "Одежда для дома", "Перчатки, шарфы, шапки"]
categories.each do |cat_title|
  cat = Category.find_or_initialize_by title: cat_title
  done = cat.new_record? ? 'Created' : 'Already exists'
  cat.save
  puts "#{done} category id #{cat.id} => #{cat_title}"
end

puts 'Creating colors ...'
colors = %w[Мультиколор Черный Белый Серый Бирюзовый Зеленый Розовый Красный Бежевый Желтый Коричневый Голубой Синий Фиолетовый Золотистый Серебристый Оранжевый Принт]
colors.each do |title|
  color = Color.find_or_initialize_by title: title
  done = color.new_record? ? 'Created' : 'Already exists'
  color.save
  puts "#{done} color id #{color.id} => #{title}"
end

puts 'Creating Product properties ...'
lengths = %w[Мини Миди Макси]
lengths.each do |length_name|
  property = Property.find_or_initialize_by name: length_name
  done = property.new_record? ? 'Created' : 'Already exists'
  property.save
  puts "#{done} property id #{property.id} => #{length_name}"
end

puts 'Creating Product Global properties ...'
types = %w[Выходная Повседневная Домашняя]
types.each do |type_name|
  property = Property.find_or_initialize_by name: type_name
  done = property.new_record? ? 'Created' : 'Already exists'
  property.save
  puts "#{done} property id #{property.id} => #{type_name}"
end

puts 'Creating Rumara brands ...'
brand_titles = ['0101', '53mission', 'A-Dress', 'A.G', 'ALDi Di', 'Alpama', 'Art Style Leggings', 'Barbarris', 'Bestia', 'Bijourin', 'Classy shoes', 'Daminika', 'DIA', 'FashionUP', 'FLF', 'Garda', 'Ghazel', 'Glem', 'InRed', 'Judi', 'Leo Pride', 'Lipar', 'Lux Look', 'Luzana', 'Majaly', 'MarSe', 'MarSe Man', 'Me&Me', 'Mila Merry', 'Modus', 'Oldisen', 'Olis-Style', 'Palvira', 'RiMari', 'Safika', 'Santali', 'Seventeen', 'Sewel', 'SK-House', 'SL Fashion', 'TALES', 'Tatiana', 'Timbo', 'Velurs', 'Vision Fashion Store', 'Vlavi', 'Zefir']
brand_titles.each do |title|
  brand = Brand.find_or_initialize_by title: title
  done = brand.new_record? ? 'Created' : 'Already exists'
  brand.save
  puts "#{done} brand id #{brand.id} => #{title}"
end

puts 'Seeding is successfully over.'
