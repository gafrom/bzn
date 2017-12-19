require 'csv'

module Export
  class CSV < Base
    include Pushable

    def single_file(how_many = nil)
      filename = "#{PATH_TO_FILE}.csv"

      ::CSV.open filename, 'wb' do |file|
        products = Product.includes(:supplier, :category).available.limit(how_many)
        push_to file, products
      end

      filename
    end

    def in_batches(batch_size = nil)
      @batch_size = batch_size || 8000

      export_additions
      export_disposals

      filenames
    end

    def fix
      ::CSV.open "#{PATH_TO_FILE}_fix.csv", 'wb' do |file|
        products = Product.includes(:supplier, :category).available.limit(how_many)
        push_to file, products, :just_id
      end

      filenames
    end

    def mapping
      ::CSV.generate do |csv|
        csv << %w[ID Title Supplier]
        push_to csv, Product.includes(:supplier, :category), :just_supplier
      end
    end

    private

    def export_additions
      batches = Product.includes(:supplier, :category).available.in_batches of: @batch_size

      batches.each_with_index do |batch, num|
        filename = "#{PATH_TO_FILE}_additions_batch_#{num + 1}.csv"
        ::CSV.open(filename, 'wb') { |file| push_to file, batch }

        filenames << filename
      end
    end

    def export_disposals
      products = Product.includes(:supplier, :category).unavailable
      filename = "#{PATH_TO_FILE}_disposals.csv"
      ::CSV.open(filename, 'wb') { |file| push_to file, products, :just_stock }

      filenames << filename
    end
  end
end
