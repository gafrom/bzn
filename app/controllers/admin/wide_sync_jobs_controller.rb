class Admin::WideSyncJobsController < AdminController
  TASKS_LIMIT = 15

  before_action :set_supplier

  def index
    @products_count = Product.available.where(supplier: @supplier).count
    @latest_product  = Product.where(supplier: @supplier).order(updated_at: :desc).first

    @tasks = DailyReportWideSyncsTask.all.limit(TASKS_LIMIT).order(id: :desc)
  end

  private

  def set_supplier
    @supplier = Supplier.main
  end
end
