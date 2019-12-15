class Admin::ReportTasksController < AdminController
  before_action :set_task, only: :enqueue

  def create
    @task = DailyReportTask.new task_params

    if @task.save
      human_dates = [@task.start_at, @task.end_at].map { |date| I18n.l(date) }
      redirect_to admin_root_path, notice: "Началось создание отчёта с #{human_dates.join(' по ')}"
    else
      redirect_to admin_root_path, alert: 'Ошибка при создании задачи'
    end
  end

  def enqueue
    return redirect_to admin_root_path, alert: 'Уже есть в очереди' if enqueued?

    DailyReportJob.perform_later @task.id
    redirect_to admin_root_path, notice: 'Работа добавлена в очередь'
  end

  private

  def task_params
    params.require(:daily_report_task).permit(:start_at, :end_at, :type)
  end

  def set_task
    @task = DailyReportTask.find(params[:id])
  end

  def enqueued?
    Sidekiq::Queue.new.find { |job| job&.args&.first&.[]('arguments')&.first == @task.id }
  end
end
