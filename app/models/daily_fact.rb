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
#  feedback_count :integer
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
  STATEMENT = <<~SQL.freeze
    SELECT f.product_id,
           f.remote_id,
           f.coupon_price,
           f.sold_count,
           f.created_at,
           array_length(f.sizes, 1) as sizes_count,
           b.title as brand_title
    FROM daily_facts f
    INNER JOIN unnest('{%{ids}}'::int[]) WITH ORDINALITY t(id, ord) USING (id)
    LEFT JOIN brands b ON f.brand_id = b.id
    ORDER BY t.ord
  SQL

  WEEKLY_WIDE_COUNT = <<~SQL.freeze
    SELECT count(*)
    FROM (
      SELECT DISTINCT ON (f.product_id, extract(week from f.created_at)) f.created_at
      FROM daily_facts f
      WHERE f.created_at BETWEEN '%{start_at}' AND '%{end_at}'
    ) weekly_wide_ids
  SQL

  WEEKLY_WIDE_IDS = <<~SQL.freeze
    SELECT resulting_facts.id
    FROM (
      SELECT DISTINCT ON (f.product_id, extract(week from f.created_at)) f.created_at, f.id
      FROM daily_facts f
      WHERE f.created_at BETWEEN '%{start_at}' AND '%{end_at}'
      ORDER BY f.product_id, extract(week from f.created_at), f.created_at
      LIMIT %{limit}
      OFFSET %{offset}
    ) resulting_facts
  SQL

  belongs_to :product
  belongs_to :category, optional: true
  belongs_to :brand, optional: true

  def self.pluck_fields_for_report(ids)
    connection.execute(STATEMENT % { ids: ids.join(',') })
  end

  def self.pluck_ids_for_weekly_wide_report(limit:, offset:, start_at:, end_at:)
    query = WEEKLY_WIDE_IDS % { limit: limit, offset: offset, start_at: start_at, end_at: end_at }
    connection.exec_query(query).rows.map(&:first)
  end

  def self.count_ids_for_weekly_wide_report(start_at:, end_at:)
    query = WEEKLY_WIDE_COUNT % { start_at: start_at, end_at: end_at }
    connection.exec_query(query).rows.first.first
  end
end
