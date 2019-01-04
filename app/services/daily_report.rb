class DailyReport
  PATH_TO_FILE = Rails.root.join 'storage', 'export'
  LOFFSET = 2 # number of columns to the left of columns with dates
  ROFFSET = 1 # number of columns between columns with dates and columns with sold_count
  BATCH_SIZE = 500

  attr_reader :start_at, :end_at, :num_days, :column_index, :filename, :facts

  def initialize(start_at, end_at)
    @start_at = start_at.to_date
    @end_at   = end_at.to_date
    @num_days = (@end_at - @start_at + 1).to_i

    @column_index = @num_days.times.reduce({}) { |hsh, n| hsh[(@start_at + n.days).yday] = n; hsh }

    @filename = "#{PATH_TO_FILE}_juice.xlsx"
    @facts_ids = DailyFact.where(created_at: @start_at..@end_at)
                          .order(:product_id, :created_at).pluck(:id)

    GC.start
  end

  def store
    Xlsxtream::Workbook.open @filename do |xlsx|
      xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
        product_id = nil
        row = headers
        prices = []

        @facts_ids.each_slice(BATCH_SIZE) do |ids|
          DailyFact.for_report.find(ids).each do |fact|
            if product_id != fact.product_id
              row[LOFFSET + @num_days] = average_price(prices) if product_id
              sheet << row
              row = [fact.brand.title, fact.remote_id]

              product_id = fact.product_id
            end

            i = @column_index[fact.created_at.yday]
            row[LOFFSET + i] = fact.sizes_count

            row[LOFFSET + @num_days + ROFFSET + 0] = fact.sold_count if i == 0
            row[LOFFSET + @num_days + ROFFSET + 1] = fact.sold_count if i == @num_days - 1

            prices[i] = fact.coupon_price
          end

          GC.start
        end

        row[LOFFSET + @num_days] = average_price(prices)
        sheet << row
      end
    end
  end

  def headers
    result = ['brand', 'remote_id']

    @num_days.times do |n|
      result << I18n.l(@start_at + n.days, format: :xlsx)
    end

    result += ['avg coupon_price', 'orders OB', 'orders CB']
  end

  def average_price(prices)
    sum = 0
    size = 0
    prices.each do |price|
      next unless price
      sum += price
      size += 1
    end

    sum.fdiv(size).to_i if size.positive?
  end
end
