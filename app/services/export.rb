require 'csv'

class Export
  CATEGORIES_DEPTH = 5
  PATH_TO_FILE = Rails.root.join('storage', 'export.csv')

  def csv(how_many = nil)
    CSV.open PATH_TO_FILE, 'wb' do |file|
      Product.limit(how_many).each do |product|
        product.to_csv { |row| file << row }
      end
    end
  end
end
