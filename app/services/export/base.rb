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
          make_unavailable! product, ex
        end
      end
    end

    def products(batch)
      batch.where.not(id: BLACKLISTED)
    end

    def make_unavailable!(product, exception)
      @results.skipped += 1
      product.is_available = false
      product.save

      msg = "⚠️  Skipped due to #{exception}"
      logger.error msg
      puts msg
    end
  end
end
