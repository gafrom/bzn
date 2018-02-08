module Collectionizer
  class << self
    def build(product)
      collections = []

      filters.each do |label, params|
        collections << label if filter_matches product, params
      end

      collections.uniq.join '##'
    end

    private

    def filters
      {
        'Вязанные платья' => { pattern: 'вязан',      category_id: 3 },
        'Тёплые платья'   => { pattern: 'т[её]плое',  category_id: 3 },
        'Платья футляр'   => { pattern: 'футляр',     category_id: 3 }
      }
    end

    def filter_matches(product, params)
      product.title.match(/#{params[:pattern]}/i) &&
        product.category_id == params[:category_id]
    end
  end
end
