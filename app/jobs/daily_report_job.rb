class DailyReportJob < ApplicationJob
  queue_as :default

  def perform(report_task_id)
    task = DailyReportTask.find_by id: report_task_id
    return unless task

    task.update_attributes dequeued_at: Time.zone.now, status: :dequeued
    DailyReport.new(task).store
    task.update_attributes status: :completed

    GC.start
  end
end
