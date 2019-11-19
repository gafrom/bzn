# == Schema Information
#
# Table name: hourly_facts
#
#  id         :integer          not null, primary key
#  product_id :integer
#  sizes      :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hourly_facts_on_created_at  (created_at)
#  index_hourly_facts_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#

class HourlyFact < ApplicationRecord
  belongs_to :product
end
