class Admin::DashboardController < AdminController
  def home
    @products_count = Product.where(supplier_id: 12).count
    @available_products_count = Product.available.where(supplier_id: 12).count
    @latest_updated_product = Product.where(supplier_id: 12).order(updated_at: :desc).first
  end
end
