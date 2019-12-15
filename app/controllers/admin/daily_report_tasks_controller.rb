class Admin::DailyReportTasksController < Admin::ReportTasksController
  private

  def report_job_class
    DailyReportJob
  end

  def report_task_class
    DailyReportTask
  end
end
