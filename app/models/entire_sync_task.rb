# == Schema Information
#
# Table name: sync_tasks
#
#  id                                 :integer          not null, primary key
#  supplier_id                        :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  type                               :string
#  initial_count                      :integer
#  total_products_counter_cache       :integer
#  processed_products_counter_cache   :integer
#  unprocessed_products_counter_cache :integer
#
# Indexes
#
#  index_sync_tasks_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#

class EntireSyncTask < SyncTask
  def enqueue_job
    EntireSyncJob.perform_later(self)
  end
end
