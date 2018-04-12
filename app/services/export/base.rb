module Export
  class Base
    attr_accessor :filenames, :logger, :results

    def initialize(*_)
      @filenames = []
      @logger = Rails.logger
      @results = Struct.new('Result', :exported, :skipped).new 0, 0
    end

    private

    def push_to(file, batch, strategy = :full)
      products(batch).each do |product|
        begin
          product.rows(strategy).each { |row| file << row }
          @results.exported += 1
        rescue NotImplementedError => ex
          @results.skipped += 1
          msg = "⚠️  Skipped due to #{ex}"
          logger.error msg
          puts msg
        end
      end
    end

    def products(batch)
      batch.where.not(id: BLACKLISTED)
    end
  end
end
