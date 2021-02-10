class WideSyncJob < ApplicationJob
  BATCH_SIZE = 10_000

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
    @task.pstings.unprocessed.in_batches(of: BATCH_SIZE) do |few_pstings|
      @task.supplier.sync_products(
        few_pstings.pluck(:product_remote_id),
        after_batch_callback: checking_off
      )
    end
  end

  private

  def set_task
    @task = arguments.first
  end

  def checking_off
    lambda do |remote_ids|
      @task.pstings.where(product_remote_id: remote_ids).update_all is_processed: true
    end
  end
end
