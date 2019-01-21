class CreateDailyReportTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :daily_report_tasks do |t|
      t.string :status
      t.date :start_at
      t.date :end_at
      t.datetime :dequeued_at
      t.string :filename

      t.timestamps
    end
  end
end
