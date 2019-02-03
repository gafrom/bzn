class Admin::DailyReportTasksController < AdminController
  before_action :set_task

  def enqueue
    return redirect_to admin_root_path, alert: 'Уже есть в очереди' if enqueued?

    DailyReportJob.perform_later @task.id
    redirect_to admin_root_path, notice: 'Работа добавлена в очередь'
  end

  private

  def set_task
    @task = DailyReportTask.find(params[:id])
  end

  def enqueued?
    Sidekiq::Queue.new.find { |job| job&.args&.first&.[]('arguments')&.first == @task.id }
  end
end
