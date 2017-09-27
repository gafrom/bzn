namespace :export do
  task csv: :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    limit = ARGV[1] ? ARGV[1].to_i : nil
    Export.new.csv limit
    puts 'CSV file is updated successfully.'
  end
end
