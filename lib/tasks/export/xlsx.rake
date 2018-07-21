namespace :export do
  task xlsx: :environment do
    limit = ENV['limit'].presence || nil
    offset = ENV['offset'].presence || nil

    export = Export::XLSX.new limit: limit, offset: offset
    Rails.logger.info "XLSX file `#{export.filename}` is composed successfully ✅\n" \
                      "Results: #{export.results}"
  end
  namespace :xlsx do
    task wb: :environment do
      file = Export::XLSX.new.succinct

      Rails.logger.info "XLSX file `#{file}` is composed successfully ✅"
    end
  end
end
