namespace :export do
  task xlsx: :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    limit = ARGV[1] ? ARGV[1].to_i : nil
    export = Export::XLSX.new limit
    puts "XLSX file `#{export.filename}` is composed successfully ✅\n" \
         "Results: #{export.results}"
  end
end
