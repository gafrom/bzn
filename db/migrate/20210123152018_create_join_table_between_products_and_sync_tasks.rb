class CreateJoinTableBetweenProductsAndSyncTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :pstings do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :sync_task, foreign_key: true

      t.index [:product_id, :sync_task_id], unique: true
    end
  end
end
