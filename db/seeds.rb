puts 'Creating root category ...'
cat_title = 'Одежда'
cat = Category.find_or_initialize_by title: cat_title
done = cat.new_record? ? 'Created' : 'Already exists'
cat.save
puts "#{done} category id #{cat.id} => #{cat_title}"

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

puts 'Seeding is successfully over.'
