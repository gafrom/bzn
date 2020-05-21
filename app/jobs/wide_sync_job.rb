class WideSyncJob < ApplicationJob
  queue_as :default

  before_perform :set_task

  def perform(*)
    links = @task.source_links.unprocessed.to_a

    @task.supplier.sync_daily(links.pluck(:url), CountingProc.new { |i| links[i].processed! })
  end

  private

  def set_task
    @task = arguments.first
  end
end
