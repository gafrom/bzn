module DailyReport
  class ByWeek < DailyReport::Base
    LOFFSET = 2 # number of columns to the left of columns with dates

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
          last_fact = nil
          row = column_names
          prices = []

          batches_of_facts_ids(categories) do |ids|
            DailyFact.pluck_fields_for_report(ids).each do |fact|
              if product_id != fact[PRODUCT_ID]
                if product_id
                  row[LOFFSET + @num_weeks * 2] = average_price(prices)
                  row[LOFFSET + @num_weeks * 2 + 1] = fact[SUBCATEGORIES]
                end

                sheet << row if row[LOFFSET...(LOFFSET + @num_weeks)].compact.any?
                row = [fact[BRAND_TITLE], fact[REMOTE_ID]]

                prices.clear
                product_id = fact[PRODUCT_ID]
              end

              i = @week_indexing[fact[CREATED_AT].to_date.cweek]
              row[LOFFSET + i] = fact[SIZES_COUNT]
              row[LOFFSET + @num_weeks + i] = fact[SOLD_COUNT]

              prices[i] = fact[COUPON_PRICE]
              last_fact = fact
            end
          end

          if last_fact
            row[LOFFSET + @num_weeks * 2] = average_price(prices)
            row[LOFFSET + @num_weeks * 2 + 1] = last_fact[SUBCATEGORIES]
            sheet << row
          end
        end
      end
    end

    def column_names
      result = [
        'brand',            # LOFFSET - 2
        'remote_id'         # LOFFSET - 1
      ]

      # columns for size lengths
      @num_weeks.times do |n|
        result << "Week #{@start_at.cweek + n} - sizes"
      end

      # columns for order counts
      @num_weeks.times do |n|
        result << "Week #{@start_at.cweek + n} - orders"
      end

      result += [
        'avg coupon_price', # LOFFSET + @num_weeks * 2
        'categories'        # LOFFSET + @num_weeks * 2 + 1
      ]
    end

    def headers
      [
        ["Weekly report for the period: #{I18n.l(@start_at.beginning_of_week, format: :xlsx)} - "\
        "#{I18n.l(@end_at.end_of_week, format: :xlsx)}."],
        ["Total weeks: #{@num_weeks}."],
        ["Creation time: #{I18n.l(Time.now, format: :xlsx)}"],
        [],
        [nil] * LOFFSET + ['Columns for size lengths'] +
                          [nil] * (@num_weeks - 1) +
                          ['Columns for order counts']
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
          start_at: @start_at.beginning_of_week,
          end_at: @end_at.end_of_week,
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
