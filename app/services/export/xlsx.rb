module Export
  class XLSX < Base
    attr_accessor :filename

    def initialize(how_many = nil)
      super
      @filename = "#{PATH_TO_FILE}.xlsx"

      Xlsxtream::Workbook.open @filename do |xlsx|
        xlsx.write_worksheet 'Sheet1' do |sheet|
          products = Product.includes(:supplier, :category).available.limit(how_many)
          push_to sheet, products
        end
      end
    end
  end
end
