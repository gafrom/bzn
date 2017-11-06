puts 'Creating root category...'
Category.find_or_create_by title: 'Одежда'

colors = %w[Мультиколор Черный Черно-белый Белый Серый Бирюзовый Зеленый Розовый Красный Бежевый Желтый Коричневый Голубой Синий Фиолетовый Золотистый Серебристый Оранжевый]

colors.each do |title|
  color = Color.find_or_create_by title: title
  puts "Created color id #{color.id} => #{title}"
end

puts 'Initial seeding is successfully over.'
