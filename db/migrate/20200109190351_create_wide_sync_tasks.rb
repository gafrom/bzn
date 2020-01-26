class CreateWideSyncTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :wide_sync_tasks do |t|
      t.belongs_to :supplier, foreign_key: true

      t.timestamps
    end
  end
end
