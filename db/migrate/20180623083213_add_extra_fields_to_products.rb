class AddExtraFieldsToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :remote_id, :integer
    add_column :products, :original_price, :integer
    add_column :products, :discount_price, :integer
    add_column :products, :coupon_price, :integer
    add_column :products, :sold_count, :integer
  end
end
