# == Schema Information
#
# Table name: wide_sync_tasks
#
#  id          :integer          not null, primary key
#  supplier_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_wide_sync_tasks_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#

class WideSyncTask < ApplicationRecord
  belongs_to :supplier

  def enqueue_job
    WideSyncJob.perform_later(id)
  end
end
