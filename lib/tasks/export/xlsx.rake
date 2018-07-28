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
      if Export.obsolete? 'succinct.xlsx'
        file = Export::XLSX.new.succinct
        Rails.logger.info "XLSX file `#{file}` is composed successfully ✅"
      else
        Rails.logger.info "File 'succinct.xlsx' is fresh yet - thus no export is done ✅"
      end
    end
  end
end
