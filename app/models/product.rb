# == Schema Information
#
# Table name: products
#
#  id           :integer          not null, primary key
#  title        :string
#  is_available :boolean
#  remote_id    :integer
#  category_id  :integer
#  supplier_id  :integer
#  url          :string
#  description  :text
#  collection   :string
#  color        :string
#  sizes        :string
#  price        :integer
#  images       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_products_on_category_id  (category_id)
#  index_products_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (supplier_id => suppliers.id)
#

class Product < ApplicationRecord
  belongs_to :category
  belongs_to :supplier
end
