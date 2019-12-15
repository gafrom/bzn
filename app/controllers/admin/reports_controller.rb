class Admin::ReportsController < ApplicationController
  def create
    @task = DailyReportTask.new task_params

    if @task.save
      human_dates = [@task.start_at, @task.end_at].map { |date| I18n.l(date) }
      redirect_to admin_root_path, notice: "Началось создание отчёта с #{human_dates.join(' по ')}"
    else
      redirect_to admin_root_path, alert: 'Ошибка при создании задачи'
    end
  end

  private

  def task_params
    params.require(:daily_report_task).permit(:start_at, :end_at, :type)
  end
end
