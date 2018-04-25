namespace :export do
  task xlsx: :environment do
    limit = ENV['limit'].presence || nil
    offset = ENV['offset'].presence || nil

    export = Export::XLSX.new limit: limit, offset: offset
    puts "XLSX file `#{export.filename}` is composed successfully ✅\n" \
         "Results: #{export.results}"
  end
end
