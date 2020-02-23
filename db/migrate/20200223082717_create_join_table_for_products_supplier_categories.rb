class CreateJoinTableForProductsSupplierCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :pscings do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :supplier_category, foreign_key: true

      t.index [:product_id, :supplier_category_id], unique: true
    end
  end
end
