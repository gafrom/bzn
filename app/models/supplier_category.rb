# == Schema Information
#
# Table name: supplier_categories
#
#  id          :integer          not null, primary key
#  name        :string
#  supplier_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_supplier_categories_on_name_and_supplier_id  (name,supplier_id)
#  index_supplier_categories_on_supplier_id           (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#

class SupplierCategory < ApplicationRecord
  has_many :pscings, dependent: :destroy
  has_many :products, through: :pscings

  belongs_to :supplier

  validates :name, presence: true
end
