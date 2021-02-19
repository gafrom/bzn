class AddStatsToSyncTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :sync_tasks, :total_products_counter_cache, :integer
    add_column :sync_tasks, :processed_products_counter_cache, :integer
    add_column :sync_tasks, :unprocessed_products_counter_cache, :integer
  end
end
