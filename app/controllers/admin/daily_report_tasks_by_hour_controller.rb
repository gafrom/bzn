class Admin::DailyReportByHourTasksController < Admin::ReportTasksController
  private

  def report_job_class
    DailyReportByHourJob
  end

  def report_task_class
    DailyReportByHourTask
  end
end
