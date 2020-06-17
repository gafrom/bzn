class DailyReport::FullOneOff
  BATCH_SIZE = 50_000

  REMOTE_ID      = 'remote_id'.freeze
  TITLE          = 'title'.freeze
  UPDATED_AT     = 'updated_at'.freeze
  ORIGINAL_PRICE = 'original_price'.freeze
  DISCOUNT_PRICE = 'discount_price'.freeze
  COUPON_PRICE   = 'coupon_price'.freeze
  FEEDBACK_COUNT = 'feedback_count'.freeze
  RATING         = 'rating'.freeze
  COLOR          = 'color'.freeze
  BRAND_TITLE    = 'brand_title'.freeze
  URL            = 'url'.freeze
  SOLD_COUNT     = 'sold_count'.freeze
  SIZES          = 'sizes'.freeze
  SUBCATEGORIES  = 'subcategories'.freeze

  FILE_PATH = Rails.root.join('storage', 'export', name.underscore.split(?/).last)

  def initialize(task)
    @task = task
    @created_at = Time.now.utc
  end

  def store
    top_level_categories.each do |category, name|
      spawn_xlsx(category, name) do |sheet|
        headers(category, name).each { |header| sheet << header }
        sheet << column_names

        batches_of_fact_ids(category) do |ids|
          DailyFact.pluck_fields_for_one_off_report(ids).each do |fact|
            sheet << [
              fact[REMOTE_ID],
              fact[TITLE],
              fact[UPDATED_AT],
              fact[ORIGINAL_PRICE],
              fact[DISCOUNT_PRICE],
              fact[COUPON_PRICE],
              fact[FEEDBACK_COUNT],
              fact[RATING],
              fact[COLOR],
              fact[BRAND_TITLE],
              fact[URL],
              fact[SOLD_COUNT],
              fact[SIZES],
              fact[SUBCATEGORIES]
            ]
          end
        end
      end
    end
  end

  private

  def top_level_categories
    @top_level_categories ||= cat_mapping.values.uniq
  end

  def cat_mapping
    @cat_mapping ||= @task.supplier.categories_mapping
  end

  def batches_of_fact_ids(category)
    return to_enum :batches_of_fact_ids unless block_given?

    names = cat_mapping.reduce([]) do |arr, (cat, pair)|
      pair.first == category ? (arr << cat.name) : arr
    end

    batch = CountingProc.new do |i|
      DailyFact.ids_for_one_off_report(names: names,
                                       limit: BATCH_SIZE,
                                       offset: i * BATCH_SIZE)
               .instance_eval { |ids| ids if ids.any? }
    end

    ids = nil
    yield ids while ids = batch.call
  end

  def column_names
    %w[
      remote_id
      title
      updated_at
      original_price
      discount_price
      coupon_price
      feedback_count
      rating
      color
      brand.title
      url
      sold_count
      sizes
      subcategories
    ]
  end

  def headers(category, name)
    [
      ["Full one-off report for \"#{name}\""],
      ["#{@task.supplier.host}#{category}"],
      ["Creation time: #{I18n.l(@created_at, format: :xlsx)}"]
    ]
  end

  def spawn_xlsx(category, name)
    name = name.gsub(/[^А-Яа-я_\-0-9]/i, ?_)
    cat = category.gsub(/[^A-Za-z0-9_\-]/i, ?_)
                  .split(?_)
                  .tap { |a| a.shift if a.size > 1 }
                  .join(?_)
    filename = FILE_PATH.join "#{I18n.l(@created_at, format: :file)}_#{cat}.xlsx"

    Dir.mkdir(FILE_PATH) unless File.directory?(FILE_PATH)

    Xlsxtream::Workbook.open(filename) do |xlsx|
      xlsx.write_worksheet(name) { |sheet| yield sheet }
    end
  end
end
