class AddTypeToDailyReportTasks < ActiveRecord::Migration[5.1]
  def up
    add_column :daily_report_tasks, :type, :string
    DailyReportTask.all.update_all type: 'DailyReportByDayTask'
  end

  def down
    remove_column :daily_report_tasks, :type
  end
end
