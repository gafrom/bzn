puts 'Creating root category ...'
cat_title = 'Одежда'
cat = Category.find_or_initialize_by title: cat_title
done = cat.new_record? ? 'Created' : 'Already exists'
cat.save
puts "#{done} category id #{cat.id} => #{cat_title}\n"

puts 'Seeding is successfully over.'
