class WideSyncJob < ApplicationJob
  queue_as :default

  before_perform :set_task

  def perform(*)
    links = @task.source_links.unprocessed.to_a

    # check what's out there
    @task.supplier.fetch_product_remote_ids(
      links.pluck(:url),
      after_url_done_callback: CountingProc.new { |i| links[i].processed! }
    ) do |remote_ids|
      @task.bulk_add_products remote_ids
    end

    # update what's assigned
    @task.supplier.sync_products(@task.products.unprocessed, after_batch_callback: checking_off)
  end

  private

  def set_task
    @task = arguments.first
  end

  def checking_off
    lambda do |products|
      @task.pstings.where(product: products).update_all is_processed: true
    end
  end
end
