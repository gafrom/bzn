class DailyReport::ByDay < DailyReport::Base
  LOFFSET = 2 # number of columns to the left of columns with dates
  ROFFSET = 1 # number of columns between columns with dates and columns with sold_count

  PRODUCT_ID   = 'product_id'.freeze
  REMOTE_ID    = 'remote_id'.freeze
  BRAND_TITLE  = 'brand_title'.freeze
  COUPON_PRICE = 'coupon_price'.freeze
  SOLD_COUNT   = 'sold_count'.freeze
  CREATED_AT   = 'created_at'.freeze
  SIZES_COUNT  = 'sizes_count'.freeze

  def initialize(task)
    super
    @facts_ids_query = DailyFact.where(created_at: @start_at..@end_at)
                                .order(:product_id, :created_at)
  end

  def store
    Xlsxtream::Workbook.open @filename do |xlsx|
      xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
        product_id = nil
        row = headers
        prices = []

        batches_of_facts_ids do |ids|
          DailyFact.pluck_fields_for_report(ids).each do |fact|
            if product_id != fact[PRODUCT_ID]
              row[LOFFSET + @num_days] = average_price(prices) if product_id
              sheet << row
              row = [fact[BRAND_TITLE], fact[REMOTE_ID]]

              product_id = fact[PRODUCT_ID]
            end

            i = @date_indexing[fact[CREATED_AT].to_date]
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
end
