class CreateJoinTableBetweenProductsAndSyncTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :pstings do |t|
      t.integer :product_remote_id, null: false, index: true
      t.integer :sync_task_id, null: false, index: true

      t.index [:product_remote_id, :sync_task_id], unique: true
    end
  end
end
