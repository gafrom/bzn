namespace :export do
  task csv: :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    Export.new.csv ARGV[1].to_i
    puts 'CSV file is updated successfully.'
  end
end
