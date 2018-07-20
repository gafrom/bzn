namespace :export do
  task xlsx: :environment do
    limit = ENV['limit'].presence || nil
    offset = ENV['offset'].presence || nil

    export = Export::XLSX.new limit: limit, offset: offset
    puts "XLSX file `#{export.filename}` is composed successfully ✅\n" \
         "Results: #{export.results}"
  end
  namespace :xlsx do
    task wb: :environment do
      file = Export::XLSX.new.succinct

      message = "XLSX file `#{file}` is composed successfully ✅"
      Rails.logger.info message
      puts message
    end
  end
end
