class WelcomeController < ApplicationController
  def home
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
