class DailyReport::Base
  include WithSpawnXlsx

  BATCH_SIZE = 250000 # it will keep memory consumption within 200Mb

  attr_reader :start_at, :end_at, :num_days, :filename, :facts

  def initialize(task)
    @task = task
    @start_at = task.start_at.to_date
    @end_at   = task.end_at.to_date
    @num_days = (@end_at - @start_at + 1).to_i

    @date_indexing = @num_days.times.reduce({}) { |hsh, n| hsh[@start_at + n.days] = n; hsh }

    @filename = task.filepath
    dir = File.dirname @filename
    Dir.mkdir dir unless File.exists? dir

    GC.start
  end

  def store
    raise NotImplementedError, 'Method `store` must be invoked from a subclass'
  end

  private

  def batches_of_facts_ids
    return to_enum :batches_of_facts_ids unless block_given?

    total = @facts_ids_query.count

    total.fdiv(BATCH_SIZE).ceil.times do |n|
      yield @facts_ids_query.limit(BATCH_SIZE).offset(n * BATCH_SIZE).pluck(:id)
    end
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

  def category_names(product_id)
    return unless product_id
    SupplierCategory.includes(:products).where('products.id': product_id).pluck(:name).join(?;)
  end
end
