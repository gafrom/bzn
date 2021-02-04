module DailyReport
  class ByWeekV2 < ByWeek
    COLOR_PICKER = {
      0 => '900000',
      1 => 'CB4B00',
      2 => 'FF8900',
      3 => 'FFBE24',
      4 => 'FFE955',
      5 => 'FCFF90',
      6 => 'F1FFB5',
      7 => nil
    }.freeze

    def store
      categories_by_groups.each do |name, categories|
        spawn_xlsx(filename_for_cat_name(name), name) do |sheet|
          headers.each { |header| sheet << header }

          product_id = nil
          last_fact = nil
          row = column_names
          prices = Hash.new { |h, k| h[k] = {} }
          sizes = Hash.new { |h, k| h[k] = {} }
          solds = Hash.new { |h, k| h[k] = {} }

          batches_of_facts_ids(categories) do |ids|
            DailyFact.pluck_fields_for_report(ids).each do |fact|
              if product_id != fact[PRODUCT_ID]
                # push the row which is currently in memory
                fill_row_from_memory(row, fact, prices, sizes, solds) if product_id
                sheet << row if row[LOFFSET...(LOFFSET + @num_weeks)].compact.any?

                # start a new row for the next product
                row = [fact[BRAND_TITLE], fact[REMOTE_ID]]
                prices.clear
                sizes.clear
                solds.clear
                product_id = fact[PRODUCT_ID]
              end

              i = week_index_from(fact)
              fact_date = fact[CREATED_AT].to_date.freeze

              sizes[i][fact_date] = fact[SIZES_COUNT]
              solds[i][fact_date] = fact[SOLD_COUNT]
              prices[i][fact_date] = fact[COUPON_PRICE]

              last_fact = fact
            end
          end

          if last_fact
            fill_row_from_memory(row, last_fact, prices, sizes, solds)
            sheet << row
          end
        end
      end
    end

    def batches_of_facts_ids(categories)
      return to_enum :batches_of_facts_ids unless block_given?

      batch = CountingProc.new do |n|
        DailyFact.ids_for_weekly_wide_report_v2(
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

      xlsx_storage_dir.join "#{@filename_base}_V2_#{cat}.xlsx"
    end

    def column_names
      super.map do |column_name|
        if column_name.include? 'sizes'
          Xlsxtream::Cell.new(column_name, fill: { color: 'B9D7C0' })
        elsif column_name.include? 'orders'
          Xlsxtream::Cell.new(column_name, fill: { color: 'B9BCD7' })
        else
          column_name
        end
      end
    end

    private

    def fill_row_from_memory(row, fact, prices, sizes, solds)
      row[LOFFSET + @num_weeks * 2 + 1] = fact[SUBCATEGORIES]

      prices_arr = prices.values.flat_map(&:values).compact
      row[LOFFSET + @num_weeks * 2] = Xlsxtream::Cell
        .new(average_price(prices_arr),
          fill: { color: COLOR_PICKER.fetch(prices_arr.length / @num_weeks) })

      @num_weeks.times do |week_index|
        sizes_arr = sizes[week_index].values.compact
        row[LOFFSET + week_index] = Xlsxtream::Cell
          .new(sizes_arr.sum, fill: { color: COLOR_PICKER.fetch(sizes_arr.length) })

        solds_arr = solds[week_index].values.compact
        row[LOFFSET + @num_weeks + week_index] = Xlsxtream::Cell
          .new(solds_arr.last, fill: { color: solds_arr.any? ? nil : COLOR_PICKER[0] })
      end
    end
  end
end
