class WideSyncJob < ApplicationJob
  queue_as :default

  before_perform :set_task

  def perform(*)
    links = @task.source_links.unprocessed.to_a

    # crawl what's out there
    @task.supplier.sync_daily(
      links.pluck(:url),
      after_url_done_callback: CountingProc.new { |i| links[i].processed! },
      after_request_processed_callback: checking_off
    )

    # update what's hidden
    @task.supplier.sync_products(@task.products, after_batch_callback: checking_off)
  end

  private

  def set_task
    @task = arguments.first
  end

  def checking_off
    lambda do |products|
      Psting.where(product_id: products, sync_task_id: @task.id).delete_all
    end
  end
end
