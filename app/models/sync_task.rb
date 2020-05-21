# == Schema Information
#
# Table name: sync_tasks
#
#  id          :integer          not null, primary key
#  supplier_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string
#
# Indexes
#
#  index_sync_tasks_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#

class SyncTask < ApplicationRecord
  belongs_to :supplier
  has_many :source_links
end
