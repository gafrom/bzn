class Admin::DashboardController < AdminController
  def home
    @total_available_products = Product.available.count

    @num_products_with_no_color =
      Product.available
             .joins('left join colorations on colorations.product_id = products.id')
             .where('colorations.color_id is null').count

    @num_dresses_with_not_all_properties =
      Product.available.where.not(id: with_both_types_of_properties).count

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

  private

  def with_both_types_of_properties
    with_length_property_and_not_dresses & with_other_properties
  end

  def with_other_properties
    Product.available.includes(:properties)
           .where(properties: { name: %w[Выходная Повседневная Домашняя] })
           .pluck(:id)
  end

  def with_length_property_and_not_dresses
    Product.available.includes(:properties)
           .where(properties: { name: %w[Мини Миди Макси] })
           .pluck(:id) |
    Product.available.includes(:properties)
           .where.not(category_id: 3)
           .pluck(:id)
  end
end
