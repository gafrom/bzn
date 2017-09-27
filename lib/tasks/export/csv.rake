namespace :export do
  task csv: :environment do
    Export.new.csv
    puts 'CSV file is updated successfully.'
  end
end
