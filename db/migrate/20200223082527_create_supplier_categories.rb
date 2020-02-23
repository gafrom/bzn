class CreateSupplierCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :supplier_categories do |t|
      t.string :name
      t.belongs_to :supplier, foreign_key: true

      t.timestamps
      t.index [:name, :supplier_id]
    end
  end
end
