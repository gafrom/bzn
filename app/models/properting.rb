# == Schema Information
#
# Table name: propertings
#
#  product_id  :integer          not null
#  property_id :integer          not null
#
# Indexes
#
#  index_propertings_on_product_id_and_property_id  (product_id,property_id)
#  index_propertings_on_property_id_and_product_id  (property_id,product_id)
#

class Properting < ApplicationRecord
  belongs_to :product
  belongs_to :property
end
