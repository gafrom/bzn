class WideSyncJob < ApplicationJob
  queue_as :default

  before_perform :set_task

  def perform
    links = @task.source_links.unprocessed.to_a

    @task.supplier.sync_daily(links).each_with_index do |link, i|
      links[i].processed!
    end
  end

  private

  def set_task
    @task = WideSyncTask.find(arguments.first)
  end
end
