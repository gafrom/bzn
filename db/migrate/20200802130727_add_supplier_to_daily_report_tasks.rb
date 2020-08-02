class AddSupplierToDailyReportTasks < ActiveRecord::Migration[5.1]
  def up
    add_column :daily_report_tasks, :supplier_id, :integer
    add_index :daily_report_tasks, :supplier_id

    DailyReportTask.all.update_all(supplier_id: Supplier.main.id)
  end

  def down
    remove_index :daily_report_tasks, :supplier_id
    remove_column :daily_report_tasks, :supplier_id
  end
end
