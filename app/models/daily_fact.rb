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
    SELECT df.product_id,
           df.remote_id,
           df.coupon_price,
           df.sold_count,
           df.created_at,
           array_length(df.sizes, 1) as sizes_count,
           b.title as brand_title,
           string_agg(sc.name, ',') as subcategories
    FROM daily_facts df
    JOIN brands b               ON df.brand_id = b.id
    JOIN pscings psc            ON df.product_id = psc.product_id
    JOIN supplier_categories sc ON psc.supplier_category_id = sc.id
    JOIN unnest('{%{ids}}'::int[]) WITH ORDINALITY t(fact_id, ord) ON df.id = t.fact_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, t.ord
    ORDER BY t.ord
  SQL

  IDS_FOR_WEEKLY_WIDE_REPORT = <<~SQL.freeze
    SELECT res_facts.df_id
    FROM (
      SELECT DISTINCT ON (df.product_id, extract(week from df.created_at))
        df.product_id as product_id,
        extract(week from df.created_at) as week_num,
        df.id as df_id
      FROM daily_facts df
      JOIN pscings psc            ON df.product_id = psc.product_id
      JOIN supplier_categories sc ON psc.supplier_category_id = sc.id
      WHERE df.created_at BETWEEN '%{start_at}' AND '%{end_at}'
        AND sc.name IN (%{sc_names})
      ORDER BY df.product_id, extract(week from df.created_at), df.created_at
      LIMIT %{limit}
      OFFSET %{offset}
    ) res_facts
    ORDER BY res_facts.product_id, res_facts.week_num
  SQL

  IDS_FOR_ONE_OFF_REPORT = <<~SQL.freeze
    SELECT ids.fact_id
    FROM (
      SELECT
        DISTINCT ON (df.product_id)
          df.product_id,
          df.id as fact_id,
          sc.name as sc_name
      FROM daily_facts df
      JOIN pscings psc ON psc.product_id = df.product_id
      JOIN supplier_categories sc ON sc.id = psc.supplier_category_id
      WHERE sc.name in (%{names})
      ORDER BY df.product_id, df.created_at desc
    ) ids
    ORDER BY ids.sc_name
    LIMIT %{limit}
    OFFSET %{offset}
  SQL

  FIELDS_FOR_ONE_OFF_REPORT = <<~SQL.freeze
    SELECT df.remote_id,
           p.title,
           df.created_at as updated_at,
           df.original_price,
           df.discount_price,
           df.coupon_price,
           df.feedback_count,
           df.rating,
           p.color,
           b.title as brand_title,
           p.url,
           df.sold_count,
           array_to_string(df.sizes, ',') as sizes,
           string_agg(sc.name, ',') as subcategories
    FROM daily_facts df
    JOIN products p             ON df.product_id = p.id
    JOIN pscings psc            ON df.product_id = psc.product_id
    JOIN supplier_categories sc ON psc.supplier_category_id = sc.id
    JOIN brandings bs           ON df.product_id = bs.product_id
    JOIN brands b               ON bs.brand_id   = b.id
    JOIN unnest('{%{ids}}'::int[]) WITH ORDINALITY t(fact_id, ord) ON df.id = t.fact_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, t.ord
    ORDER BY t.ord
  SQL

  belongs_to :product
  belongs_to :category, optional: true
  belongs_to :brand, optional: true

  def self.pluck_fields_for_report(ids)
    connection.execute(STATEMENT % { ids: ids.join(',') })
  end

  def self.ids_for_one_off_report(names:, limit:, offset:)
    names = names.map { |text| "'#{text}'" }.join(?,)
    query = IDS_FOR_ONE_OFF_REPORT % { names: names, limit: limit, offset: offset }
    connection.exec_query(query).rows.map(&:first)
  end

  def self.pluck_fields_for_one_off_report(ids)
    connection.execute(FIELDS_FOR_ONE_OFF_REPORT % { ids: ids.join(?,) })
  end

  def self.ids_for_weekly_wide_report(limit:, offset:, start_at:, end_at:, categories:)
    sc_names = categories.map { |text| "'#{text}'" }.join(?,)
    query = IDS_FOR_WEEKLY_WIDE_REPORT % {
      limit: limit,
      offset: offset,
      sc_names: sc_names,
      start_at: start_at,
      end_at: end_at
    }

    connection.exec_query(query).rows.map(&:first)
  end
end
