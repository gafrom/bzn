class AddIsProcessedToPstings < ActiveRecord::Migration[5.1]
  def change
    add_column :pstings, :is_processed, :boolean, default: false

    add_index :pstings, [:sync_task_id, :is_processed], name: :index_on_task_id_and_is_processed
    add_index :pstings, [:product_remote_id, :sync_task_id, :is_processed], name: :full_index
  end
end
