# == Schema Information
#
# Table name: pscings
#
#  id                   :integer          not null, primary key
#  product_id           :integer
#  supplier_category_id :integer
#
# Indexes
#
#  index_pscings_on_product_id                           (product_id)
#  index_pscings_on_product_id_and_supplier_category_id  (product_id,supplier_category_id) UNIQUE
#  index_pscings_on_supplier_category_id                 (supplier_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (supplier_category_id => supplier_categories.id)
#

class Pscing < ApplicationRecord
  belongs_to :product
  belongs_to :supplier_category
end
