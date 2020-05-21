class AddTypeToSyncTasks < ActiveRecord::Migration[5.1]
  def up
    add_column :sync_tasks, :type, :string
    SyncTask.connection.execute(
      "UPDATE sync_tasks "\
      "SET type = 'WideSyncTask' "\
      "WHERE created_at < '2020-05-22';"
    )
  end

  def down
    remove_column :sync_tasks, :type
  end
end
