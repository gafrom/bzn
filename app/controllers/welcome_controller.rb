class WelcomeController < ApplicationController
  def home
    @total_available_products = Product.available.count

    @export_files_attrs = Dir["#{Export::PATH_TO_FILE}*.csv"].map do |filename|
      File.open(filename) { |io| { name: filename[/export(.*)\.csv/,1],
                                   size: io.size,
                                   updated_at: io.mtime } }
    end

    @suppliers = Supplier.all.map do |supplier|
      host = Product::PROXY_HOST if Rails.env.development?
      products = supplier.products.order(updated_at: :desc)
      last_product = products.first
      {
        id: supplier.id,
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
