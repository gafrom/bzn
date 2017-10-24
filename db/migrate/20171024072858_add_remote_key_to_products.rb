class AddRemoteKeyToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :remote_key, :string, index: true
  end
end
