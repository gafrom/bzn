# == Schema Information
#
# Table name: daily_facts
#
#  id             :integer          not null, primary key
#  remote_id      :integer
#  product_id     :integer
#  category_id    :integer
#  brand_id       :integer
#  original_price :integer
#  discount_price :integer
#  coupon_price   :integer
#  sold_count     :integer
#  rating         :integer
#  is_available   :boolean
#  sizes          :string           default([]), is an Array
#  created_at     :date             not null
#
# Indexes
#
#  index_daily_facts_on_brand_id                   (brand_id)
#  index_daily_facts_on_category_id                (category_id)
#  index_daily_facts_on_created_at                 (created_at)
#  index_daily_facts_on_product_id                 (product_id)
#  index_daily_facts_on_product_id_and_created_at  (product_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (product_id => products.id)
#

class DailyFact < ApplicationRecord
  belongs_to :product
  belongs_to :category, optional: true
  belongs_to :brand, optional: true

  scope(:between, ->(start_at, end_at) {
    select('product_id, remote_id, created_at, sold_count, array_length(sizes, 1) as sizes_count')
      .where(created_at: start_at..end_at)
  })
end
