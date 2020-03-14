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

    join_str = 'JOIN pscings ON pscings.product_id = daily_facts.product_id '\
               'JOIN supplier_categories ON supplier_categories.id = pscings.supplier_category_id'
    narrow_sync_name = Supplier.find(12).each_url_for(:narrow_sync).to_a
                               .first.split(??).first
    @facts_ids_query = DailyFact.where(created_at: @start_at..@end_at)
                                .joins(join_str)
                                .where("supplier_categories.name = '#{narrow_sync_name}'")
                                .order(:product_id, :created_at)
  end

  def store
    Xlsxtream::Workbook.open @filename do |xlsx|
      xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
        sheet << top_headers

        product_id = nil
        row = headers
        prices = []

        batches_of_facts_ids do |ids|
          DailyFact.pluck_fields_for_report(ids).each do |fact|
            if product_id != fact[PRODUCT_ID]
              if product_id
                row[LOFFSET + @num_days] = average_price(prices)
                row[LOFFSET + @num_days + ROFFSET + 2] = category_names(product_id)
              end
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
        row[LOFFSET + @num_days + ROFFSET + 2] = category_names(product_id)
        sheet << row
      end
    end
  end

  def top_headers
    [
      "Daily report for the period: #{I18n.l(@start_at, format: :xlsx)} - "\
      "#{I18n.l(@end_at, format: :xlsx)}. Creation time: #{I18n.l(Time.now, format: :xlsx)}"
    ]
  end

  def headers
    result = [
      'brand',            # LOFFSET - 2
      'remote_id'         # LOFFSET - 1
    ]

    @num_days.times do |n|
      result << I18n.l(@start_at + n.days, format: :xlsx)
    end

    result += [
      'avg coupon_price', # LOFFSET + @num_days
      'orders OB',        # LOFFSET + @num_days + ROFFSET
      'orders CB',        # LOFFSET + @num_days + ROFFSET + 1
      'categories'        # LOFFSET + @num_days + ROFFSET + 2
    ]
  end
end
