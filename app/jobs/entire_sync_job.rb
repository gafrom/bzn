class EntireSyncJob < ApplicationJob
  queue_as :default

  before_perform :set_task

  def perform(*)
    links = @task.source_links.unprocessed.to_a
    supplier.sync_once(links.pluck(:url), callback(links))
  end

  private

  def set_task
    @task = arguments.first
  end

  def callback(links)
    CountingProc.new do |i|
      link = links[i]
      # we set it as processed here because the longest part is behind
      # and any potential errors that could happen below will be fixed
      # in the next loop thanks to the design of a select statement below
      link.processed!

      products = Product.where created_at: 15.minutes.ago..Time.now, sold_count: nil
      log_intent(products.size, link.url)

      supplier.sync_orders_counts(products)
    end
  end

  def supplier
    @task.supplier
  end

  def log_intent(size, url)
    msg = "[COUNTING_PROC] Filling sold_count for #{size} "\
          "products after finishing up on #{url}"
    supplier.logger.info(msg)
  end
end
