class DailyReportJob < ApplicationJob
  queue_as :default

  def perform(report_task_id)
    task = DailyReportTask.find_by id: report_task_id
    return unless task

    task.update_attributes dequeued_at: Time.zone.now, status: :dequeued
    # to address the memory leak issue https://github.com/mperham/sidekiq/issues/3752
    ActiveRecord::Base.uncached { DailyReport::Factory.build(task).store }
    task.update_attributes status: :completed

    GC.start
  end
end
