class AddLengthToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :length, :integer
  end
end
