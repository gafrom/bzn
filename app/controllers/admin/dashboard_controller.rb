class Admin::DashboardController < AdminController
  def home
    @total_available_products = Product.available.count

    @num_products_with_no_color =
      Product.available
             .joins('left join colorations on colorations.product_id = products.id')
             .where('colorations.color_id is null').count

    @num_dresses_with_no_length =
      Product.available.where(category_id: 3).includes(:propertings).where(propertings: { property_id: nil }).count

    @export_files_attrs = Dir["#{Export::PATH_TO_FILE}*"].map do |filename|
      File.open(filename) { |io| { name: filename[/export(.*)\.\w+\Z/,1],
                                   size: io.size,
                                   updated_at: io.mtime } }
    end

    @suppliers = Supplier.all.map do |supplier|
      host = Product::PROXY_HOST if Rails.env.development?
      products = supplier.products.order(updated_at: :desc)
      last_product = products.first
      {
        name: supplier.name,
        rel_image: "#{host}/#{supplier.slug}#{last_product.images.first}",
        last_product: last_product,
        total: products.count,
        available: products.available.count,
        no_color: products.available.where(color: nil).count
      }
    end
  end
end
