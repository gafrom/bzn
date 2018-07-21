module Export
  class XLSX < Base
    attr_accessor :filename

    def main
      @filename = "#{PATH_TO_FILE}.xlsx"
      Xlsxtream::Workbook.open filename do |xlsx|
        xlsx.write_worksheet 'Sheet1' do |sheet|
          products = Product.includes(:supplier, :category, :brand)
                            .available.limit(@limit).offset(@offset)
          push_to sheet, products
        end
      end

      filename
    end

    def succinct
      @filename = "#{PATH_TO_FILE}_succinct.xlsx"

      Xlsxtream::Workbook.open filename do |xlsx|
        xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
          sheet << Product.headers(:succinct)

          products = Product.includes(:supplier, :category, :brand)
                            .where(supplier_id: 12)
                            .order(created_at: :desc)

          push_each_to sheet, products, :succinct
        end
      end

      filename
    end
  end
end
