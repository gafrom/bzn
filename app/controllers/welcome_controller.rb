class WelcomeController < ApplicationController
  def home
    @suppliers = Supplier.all.map do |supplier|
      {
        name: supplier.name,
        updated_at: supplier.products.order(updated_at: :desc).first.updated_at,
        total: supplier.products.count,
        available: supplier.products.available.count,
        no_color: supplier.products.available.where(color: nil).count
      }
    end
  end
end
