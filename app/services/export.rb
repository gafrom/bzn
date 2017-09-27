require 'csv'

class Export
  CATEGORIES_DEPTH = 5
  PATH_TO_FILE = Rails.root.join('storage', 'export.csv')

  def csv
    CSV.open PATH_TO_FILE, 'wb' do |file|
      Product.all.each do |product|
        product.to_csv { |row| file << row }
      end
    end
  end
end
