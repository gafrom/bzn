# == Schema Information
#
# Table name: source_links
#
#  id                :integer          not null, primary key
#  wide_sync_task_id :integer
#  status            :string
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_source_links_on_wide_sync_task_id  (wide_sync_task_id)
#
# Foreign Keys
#
#  fk_rails_...  (wide_sync_task_id => wide_sync_tasks.id)
#

class SourceLink < ApplicationRecord
  belongs_to :wide_sync_task

  after_create :set_initial_status

  private

  def set_initial_status
    self.status = :unprocessed unless status
  end
end
