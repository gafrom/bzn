class AddCategoryPathToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :category_path, :string, index: true
  end
end
