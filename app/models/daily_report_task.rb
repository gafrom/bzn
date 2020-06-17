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

class DailyReportTask < ApplicationRecord
  KEEP = 15 # tasks at most
  DIR = Rails.root.join 'storage', 'export'

  validates :start_at, :end_at, presence: true

  before_create :set_filename, :set_status
  after_create :delete_old_tasks
  after_destroy :remove_file
  after_commit :enqueue_job, on: :create

  def filepath
    return unless filename
    DIR.join filename
  end

  private

  def set_filename
    return if filename
    self.filename = "#{dashed_class_name}--#{start_at}-#{end_at}--#{SecureRandom.hex(3)}.xlsx"
  end

  def dashed_class_name
    self.class.model_name.plural.tr('_','-')
  end

  def set_status
    self.status = :created
  end

  def delete_old_tasks
    self.class.all.order(id: :desc).offset(KEEP).destroy_all
  end

  def remove_file
    File.delete filepath if filepath && File.exists?(filepath)
  end

  def enqueue_job
    DailyReportJob.perform_later(id)
  end
end
