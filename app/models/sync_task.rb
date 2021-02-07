# == Schema Information
#
# Table name: sync_tasks
#
#  id            :integer          not null, primary key
#  supplier_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  type          :string
#  initial_count :integer
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
  has_many :pstings
  has_many :products, through: :pstings, primary_key: :remote_id do
    def processed
      where(pstings: { is_processed: true })
    end

    def unprocessed
      where(pstings: { is_processed: false })
    end
  end

  def bulk_add_products(primary_keys)
    existing = Psting
      .where(sync_task_id: id, product_remote_id: primary_keys)
      .pluck(:product_remote_id)

    to_be_added = primary_keys - existing
    return unless to_be_added.any?

    Psting.bulk_insert(to_be_added.map { |pid| "(#{pid},#{id})" }.join(?,))
  end
end

