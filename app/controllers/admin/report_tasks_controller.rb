class Admin::ReportTasksController < AdminController
  before_action :set_task

  def enqueue
    return redirect_to admin_root_path, alert: 'Уже есть в очереди' if enqueued?

    report_job_class.perform_later @task.id
    redirect_to admin_root_path, notice: 'Работа добавлена в очередь'
  end

  private

  def set_task
    @task = report_task_class.find(params[:id])
  end

  def enqueued?
    Sidekiq::Queue.new.find { |job| job&.args&.first&.[]('arguments')&.first == @task.id }
  end
end
