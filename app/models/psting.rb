# == Schema Information
#
# Table name: pstings
#
#  id                :integer          not null, primary key
#  product_remote_id :integer          not null
#  sync_task_id      :integer          not null
#  is_processed      :boolean          default(FALSE)
#
# Indexes
#
#  full_index                                           (product_remote_id,sync_task_id,is_processed)
#  index_on_task_id_and_is_processed                    (sync_task_id,is_processed)
#  index_pstings_on_product_remote_id                   (product_remote_id)
#  index_pstings_on_product_remote_id_and_sync_task_id  (product_remote_id,sync_task_id) UNIQUE
#  index_pstings_on_sync_task_id                        (sync_task_id)
#

class Psting < ApplicationRecord
  belongs_to :product, foreign_key: :product_remote_id, primary_key: :remote_id
  belongs_to :sync_task

  def self.bulk_insert(values)
    connection.execute("INSERT INTO pstings (product_remote_id, sync_task_id) VALUES #{values};")
  end
end
