module DailyReport
  class ByWeek < DailyReport::Base
    LOFFSET = 2 # number of columns to the left of columns with dates
    ROFFSET = 1 # number of columns between columns with dates and columns with sold_count

    PRODUCT_ID   = 'product_id'.freeze
    REMOTE_ID    = 'remote_id'.freeze
    BRAND_TITLE  = 'brand_title'.freeze
    COUPON_PRICE = 'coupon_price'.freeze
    SOLD_COUNT   = 'sold_count'.freeze
    CREATED_AT   = 'created_at'.freeze
    SIZES_COUNT  = 'sizes_count'.freeze
    SUBCATEGORIES = 'subcategories'.freeze

    def initialize(task)
      super
      @num_weeks = (@end_at.cweek - @start_at.cweek + 1).to_i
      @week_indexing = @num_weeks.times.reduce({}) { |hsh, n| hsh[@start_at.cweek + n] = n; hsh }

      @filename_base = @task.filename_base
    end

    def store
      categories_by_groups.each do |name, categories|
        spawn_xlsx(filename_for_cat_name(name), name) do |sheet|
          headers.each { |header| sheet << header }

          product_id = nil
          row = column_names
          prices = []

          batches_of_facts_ids(categories) do |ids|
            DailyFact.pluck_fields_for_report(ids).each do |fact|
              if product_id != fact[PRODUCT_ID]
                if product_id
                  row[LOFFSET + @num_weeks] = average_price(prices)
                  row[LOFFSET + @num_weeks + ROFFSET + 2] = fact[SUBCATEGORIES]
                end
                sheet << row if row[LOFFSET...(LOFFSET + @num_weeks)].compact.any?
                row = [fact[BRAND_TITLE], fact[REMOTE_ID]]

                product_id = fact[PRODUCT_ID]
              end

              i = @week_indexing[fact[CREATED_AT].to_date.cweek]
              row[LOFFSET + i] = fact[SIZES_COUNT]

              row[LOFFSET + @num_weeks + ROFFSET + 0] = fact[SOLD_COUNT] if i == 0
              row[LOFFSET + @num_weeks + ROFFSET + 1] = fact[SOLD_COUNT] if i == @num_weeks - 1

              prices[i] = fact[COUPON_PRICE]
            end
          end

          row[LOFFSET + @num_weeks] = average_price(prices)
          sheet << row
        end
      end
    end

    def column_names
      result = [
        'brand',            # LOFFSET - 2
        'remote_id'         # LOFFSET - 1
      ]

      @num_weeks.times do |n|
        result << "Week #{@start_at.cweek + n}"
      end

      result += [
        'avg coupon_price', # LOFFSET + @num_weeks
        'orders OB',        # LOFFSET + @num_weeks + ROFFSET
        'orders CB',        # LOFFSET + @num_weeks + ROFFSET + 1
        'categories'        # LOFFSET + @num_weeks + ROFFSET + 2
      ]
    end

    def headers
      [
        ["Weekly report for the period: #{I18n.l(@start_at, format: :xlsx)} - "\
        "#{I18n.l(@end_at, format: :xlsx)}."],
        ["Total weeks: #{@num_weeks}."],
        ["Creation time: #{I18n.l(Time.now, format: :xlsx)}"]
      ]
    end

    def categories_by_groups
      @categories_by_groups ||= @task.supplier.wide_categories_by_groups
    end

    def batches_of_facts_ids(categories)
      return to_enum :batches_of_facts_ids unless block_given?

      batch = CountingProc.new do |n|
        DailyFact.ids_for_weekly_wide_report(
          limit: BATCH_SIZE,
          offset: n * BATCH_SIZE,
          start_at: @start_at.beginning_of_day,
          end_at: @end_at.end_of_day,
          categories: categories
        ).instance_eval { |ids| ids if ids.any? }
      end

      ids = nil
      yield ids while ids = batch.call
    end

    def filename_for_cat_name(text)
      cat = text.gsub(/[^A-Za-z0-9_\-]/i, ?_)
                .split(?_)
                .tap { |a| a.shift if a.size > 1 }
                .join(?_)

      xlsx_storage_dir.join "#{@filename_base}_#{cat}.xlsx"
    end
  end
end
