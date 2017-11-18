require 'csv'

module Export
  CATEGORIES_DEPTH = 5
  PATH_TO_FILE = Rails.root.join('storage', 'export')

  class CSV
    def initialize
      @filenames = []
    end

    def single_file(how_many = nil)
      ::CSV.open "#{PATH_TO_FILE}.csv", 'wb' do |file|
        products = Product.includes(:supplier, :category).available.limit(how_many)
        csv_push products, file
      end

      filenames
    end

    def in_batches(batch_size = nil)
      @batch_size = batch_size || 7000

      export_additions
      export_disposals

      filenames
    end

    def fix
      ::CSV.open "#{PATH_TO_FILE}_fix.csv", 'wb' do |file|
        products = Product.includes(:supplier, :category).available.limit(how_many)
        csv_push products, file, :just_id
      end

      filenames
    end

    private

    def export_additions
      batches = Product.includes(:supplier, :category).available.in_batches of: @batch_size

      batches.each_with_index do |batch, num|
        filename = "#{PATH_TO_FILE}_additions_batch_#{num + 1}.csv"
        ::CSV.open(filename, 'wb') { |file| csv_push batch, file }
      end
    end

    def export_disposals
      products = Product.includes(:supplier, :category).unavailable
      filename = "#{PATH_TO_FILE}_disposals.csv"
      ::CSV.open(filename, 'wb') { |file| csv_push products, file, :just_stock }
    end

    def csv_push(batch, file, strategy = :full)
      batch.each do |product|
        product.to_csv(strategy) { |row| file << row }
      end

      @filenames << file.path
    end

    def filenames
      @filenames.size == 1 ? @filenames.first : @filenames
    end
  end
end
