# == Schema Information
#
# Table name: pstings
#
#  id           :integer          not null, primary key
#  product_id   :integer
#  sync_task_id :integer
#
# Indexes
#
#  index_pstings_on_product_id                   (product_id)
#  index_pstings_on_product_id_and_sync_task_id  (product_id,sync_task_id) UNIQUE
#  index_pstings_on_sync_task_id                 (sync_task_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (sync_task_id => sync_tasks.id)
#


class Psting < ApplicationRecord
  belongs_to :product
  belongs_to :sync_task
end
