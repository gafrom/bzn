# == Schema Information
#
# Table name: brandings
#
#  id         :integer          not null, primary key
#  product_id :integer
#  brand_id   :integer
#
# Indexes
#
#  index_brandings_on_brand_id    (brand_id)
#  index_brandings_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#  fk_rails_...  (product_id => products.id)
#

class Branding < ApplicationRecord
  belongs_to :product
  belongs_to :brand
end
