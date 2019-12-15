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
#

class DailyReportByDayTask < DailyReportTask
end
