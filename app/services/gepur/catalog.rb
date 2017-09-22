module Gepur
  class Catalog
    FILENAME = 'gepur_catalog.csv'
    URI = URI('https://gepur.com/xml/gepur_catalog.csv')

    def update
      IO.copy_stream(open(URI), FILENAME)
    end

    def read
      # Gepur catalog csv contains two concatenated tables:
      # - Categories with headers 'id, category, parentId'
      # - Products with headers 'id_product, avaliable, ...'
      #
      # That is why we start by reading categories
      reading = :categories

      CSV.foreach FILENAME do |row|
        next reading = :products if row[0] == 'id_product'

        store row, reading
      end
    end

    private

    def store(categories_or_products)

    end

  end
end
