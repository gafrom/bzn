# == Schema Information
#
# Table name: daily_report_tasks
#
#  id          :integer          not null, primary key
#  status      :string
#  start_at    :date
#  end_at      :date
#  dequeued_at :datetime
#  filename    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string
#  supplier_id :integer
#
# Indexes
#
#  index_daily_report_tasks_on_supplier_id  (supplier_id)
#

class FullOneOffReportTask < DailyReportTask
  before_validation :mock_required_fields

  private

  def mock_required_fields
    self.start_at = Time.now
    self.end_at = Time.now
  end
end
