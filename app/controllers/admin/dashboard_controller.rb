class Admin::DashboardController < AdminController
  TASKS_LIMIT = 15

  def home
    @products_count         = Product.where(supplier_id: 12).count
    @narrow_available_count = Product.available.where(supplier_id: 12, category_id: 3).count
    @wide_available_count   = Product.available.where(supplier_id: 12).count
    @latest_updated_product = Product.where(supplier_id: 12).order(updated_at: :desc).first

    @tasks = DailyReportTask.all.limit(TASKS_LIMIT).order(id: :desc)
  end
end
