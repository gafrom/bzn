namespace :export do
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
