class DailyReport
  PATH_TO_FILE = Rails.root.join 'storage', 'export'
  OFFSET = 1 # number of columns to the left of columns with dates

  attr_reader :start_at, :end_at, :num_days, :column_index, :filename, :facts

  def initialize(start_at, end_at)
    @start_at = start_at.to_date
    @end_at   = end_at.to_date
    @num_days = (@end_at.yday - @start_at.yday + 1).to_i

    @column_index = @num_days.times.reduce({}) { |hsh, n| hsh[(@start_at + n.days).yday] = n; hsh }

    @filename = "#{PATH_TO_FILE}_juice.xlsx"
    @facts = DailyFact.between(@start_at, @end_at).order(:product_id, :created_at)
  end

  def store
    Xlsxtream::Workbook.open @filename do |xlsx|
      xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
        product_id = nil
        row = headers

        @facts.each do |fact| # do not use batches since sort order is not retained
          if product_id != fact.product_id
            sheet << row
            product_id = fact.product_id
            row = [fact.remote_id]
          end

          i = @column_index[fact.created_at.yday]
          row[OFFSET + i] = fact.sizes_count

          row[OFFSET + @num_days + 0] = fact.sold_count if i == 0
          row[OFFSET + @num_days + 1] = fact.sold_count if i == @num_days - 1
        end

        sheet << row
      end
    end
  end

  def headers
    result = ['remote_id']

    @num_days.times do |n|
      result << I18n.l(@start_at + n.days, format: :xlsx)
    end

    result += ['orders OB', 'orders CB']
  end
end
