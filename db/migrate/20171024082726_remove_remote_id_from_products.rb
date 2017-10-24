class RemoveRemoteIdFromProducts < ActiveRecord::Migration[5.1]
  def change
    remove_column :products, :remote_id
  end
end
