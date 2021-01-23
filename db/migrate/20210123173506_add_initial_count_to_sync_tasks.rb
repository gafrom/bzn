class AddInitialCountToSyncTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :sync_tasks, :initial_count, :integer
  end
end
