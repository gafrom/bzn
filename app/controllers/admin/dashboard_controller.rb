class Admin::DashboardController < AdminController
  TASKS_LIMIT = 15

  before_action :set_supplier

  def home
    @latest_updated_product = Product.where(supplier: @supplier).order(updated_at: :desc).first
    # cheating with total count to speed up performance
    @products_count = @latest_updated_product.id

    @tasks = DailyReportTask.all.limit(TASKS_LIMIT).order(id: :desc)
  end

  private

  # def narrow_products
  #   narrow_sync_name = @supplier.each_url_for(:narrow_sync).to_a.first.split(??).first
  #   join_str = 'JOIN pscings ON pscings.product_id = products.id '\
  #              'JOIN supplier_categories ON supplier_categories.id = pscings.supplier_category_id'

  #   Product.available.where(supplier: @supplier).joins(join_str)
  #          .where("supplier_categories.name = '#{narrow_sync_name}'")
  # end

  def set_supplier
    @supplier = Supplier.main
  end
end
