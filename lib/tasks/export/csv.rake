namespace :export do
  task csv: :environment do
    ARGV.each { |a| task a.to_sym do ; end }

    limit = ARGV[1] ? ARGV[1].to_i : nil
    file = Export::CSV.new.single_file limit
    Rails.logger.info "CSV file `#{file}` is composed successfully ✅"
  end
  namespace :csv do
    task batch: :environment do
      ARGV.each { |a| task a.to_sym do ; end }

      batch_size = ARGV[1] ? ARGV[1].to_i : nil
      files = Export::CSV.new.in_batches batch_size

      files.map! { |file| "#{file} ✅" }
      Rails.logger.info "The following CSV files are composed successfully:\n#{files.join("\n")}"
    end
    task wb: :environment do
      file = Export::CSV.new.succinct

      Rails.logger.info "CSV file `#{file}` is composed successfully ✅"
    end
  end
end
