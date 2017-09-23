module Gepur
  class Catalog
    FILENAME = 'gepur_catalog.csv'
    URI = URI('https://gepur.com/xml/gepur_catalog.csv')

    def update
      IO.copy_stream open(URI), FILENAME
    end

    def read
      # Gepur catalog csv contains two concatenated tables:
      # - First goes Categories with headers `id, category, parentId`
      # - Then Products with headers `id_product, avaliable, ...`
      reading = nil
      CSV.foreach FILENAME do |row|
        if row[1] == 'category'
          next reading = :categories
        elsif row[0] == 'id_product'
          next reading = :products
        end

        store row, reading
      end
    end

    private

    def store(data, type)
      
    end
  end
end
