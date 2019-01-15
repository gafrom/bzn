class DailyReport
  PATH_TO_FILE = Rails.root.join 'storage', 'export'
  LOFFSET = 2 # number of columns to the left of columns with dates
  ROFFSET = 1 # number of columns between columns with dates and columns with sold_count
  BATCH_SIZE = 10000

  PRODUCT_ID   = 'product_id'.freeze
  REMOTE_ID    = 'remote_id'.freeze
  BRAND_TITLE  = 'brand_title'.freeze
  COUPON_PRICE = 'coupon_price'.freeze
  SOLD_COUNT   = 'sold_count'.freeze
  CREATED_AT   = 'created_at'.freeze
  SIZES_COUNT  = 'sizes_count'.freeze

  attr_reader :start_at, :end_at, :num_days, :column_index, :filename, :facts

  def initialize(start_at, end_at)
    @start_at = start_at.to_date
    @end_at   = end_at.to_date
    @num_days = (@end_at - @start_at + 1).to_i

    @column_index = @num_days.times.reduce({}) { |hsh, n| hsh[@start_at + n.days] = n; hsh }

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
          DailyFact.pluck_fields_for_report(ids).each do |fact|
            if product_id != fact[PRODUCT_ID]
              row[LOFFSET + @num_days] = average_price(prices) if product_id
              sheet << row
              row = [fact[BRAND_TITLE], fact[REMOTE_ID]]

              product_id = fact[PRODUCT_ID]
            end

            i = @column_index[fact[CREATED_AT].to_date]
            row[LOFFSET + i] = fact[SIZES_COUNT]

            row[LOFFSET + @num_days + ROFFSET + 0] = fact[SOLD_COUNT] if i == 0
            row[LOFFSET + @num_days + ROFFSET + 1] = fact[SOLD_COUNT] if i == @num_days - 1

            prices[i] = fact[COUPON_PRICE]
          end
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
