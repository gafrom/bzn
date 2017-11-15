namespace :export do
  task csv: :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    limit = ARGV[1] ? ARGV[1].to_i : nil
    file = Export.new.csv limit
    puts "CSV file `#{file}` is composed successfully ✅"
  end
  namespace :csv do
    task batch: :environment do
      ARGV.each { |a| task a.to_sym do ; end }

      batch_size = ARGV[1] ? ARGV[1].to_i : nil
      files = Export.new.csv_in_batches batch_size

      files.map! { |file| "#{file} ✅" }
      puts "The following CSV files are composed successfully:\n#{files.join("\n")}"
    end
  end
end
