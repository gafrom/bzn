# == Schema Information
#
# Table name: colorations
#
#  id         :integer          not null, primary key
#  product_id :integer
#  color_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_colorations_on_color_id    (color_id)
#  index_colorations_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (color_id => colors.id)
#  fk_rails_...  (product_id => products.id)
#

class Coloration < ApplicationRecord
  belongs_to :product
  belongs_to :color
end
