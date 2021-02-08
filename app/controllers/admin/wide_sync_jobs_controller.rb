class Admin::WideSyncJobsController < AdminController
  TASKS_LIMIT = 10

  before_action :set_supplier

  def index
    @latest_product  = Product.where(supplier: @supplier).order(created_at: :desc).first
    # rough approximation of total count
    @products_count = @latest_product.id

    @tasks = DailyReportWideSyncsTask.all.limit(TASKS_LIMIT).order(id: :desc)
    @sync_tasks = WideSyncTask.all.limit(TASKS_LIMIT).order(id: :desc)
  end

  private

  def set_supplier
    @supplier = Supplier.main
  end
end
