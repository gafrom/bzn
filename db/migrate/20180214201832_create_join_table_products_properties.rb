class CreateJoinTableProductsProperties < ActiveRecord::Migration[5.1]
  def change
    create_join_table :products, :properties, table_name: :propertings do |t|
      t.index [:product_id, :property_id]
      t.index [:property_id, :product_id]
    end
  end
end
