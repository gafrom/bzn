module Export
  class Base
    attr_accessor :filenames

    def initialize
      @filenames = []
    end

    private

    def push_to(file, batch, strategy = :full)
      products(batch).each { |product| product.rows(strategy).each { |row| file << row } }
    end

    def products(batch)
      batch.where.not(id: BLACKLISTED)
    end
  end
end
