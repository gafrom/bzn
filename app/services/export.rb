require 'csv'

class Export
  CATEGORIES_DEPTH = 5
  PATH_TO_FILE = Rails.root.join('storage', 'export')

  def initialize
    @files = []
  end

  def csv(how_many = nil)
    CSV.open "#{PATH_TO_FILE}.csv", 'wb' do |file|
      push Product.available.includes(:supplier, :category).limit(how_many), file
    end

    result
  end

  def csv_in_batches(batch_size = nil)
    batch_size ||= 7000

    Product.available
           .includes(:supplier, :category)
           .in_batches(of: batch_size)
           .each_with_index do |batch, num|
      CSV.open("#{PATH_TO_FILE}_batch_#{num + 1}.csv", 'wb') { |file| push batch, file }
    end

    result
  end

  private

  def push(batch, file)
    batch.each do |product|
      product.to_csv { |row| file << row }
    end

    @files << file.path
  end

  def result
    @files.size == 1 ? @files.first : @files
  end
end
