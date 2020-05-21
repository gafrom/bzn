# == Schema Information
#
# Table name: source_links
#
#  id           :integer          not null, primary key
#  sync_task_id :integer
#  status       :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_source_links_on_sync_task_id  (sync_task_id)
#
# Foreign Keys
#
#  fk_rails_...  (sync_task_id => sync_tasks.id)
#

class SourceLink < ApplicationRecord
  belongs_to :sync_task

  before_create :set_initial_status

  enum status: { unprocessed: 'unprocessed', processed: 'processed' }

  private

  def set_initial_status
    self.status = :unprocessed unless status
  end
end
