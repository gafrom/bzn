class AddIndexOnRemoteIdToProducts < ActiveRecord::Migration[5.1]
  def change
    add_index :products, :remote_id
  end
end
