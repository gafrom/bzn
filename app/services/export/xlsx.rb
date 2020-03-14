module Export
  class XLSX < Base
    attr_accessor :filename

    def succinct
      @filename = PATH_TO_FILE.join 'succinct.xlsx'

      Xlsxtream::Workbook.open filename do |xlsx|
        xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
          sheet << Product.headers(:succinct)

          products = Product.includes(:supplier, :category, :brand)
                            .where(supplier_id: 12)
                            .where('updated_at > ?', 2.weeks.ago)
                            .order(created_at: :desc)

          push_each_to sheet, products, :succinct
        end
      end

      filename
    end
  end
end
