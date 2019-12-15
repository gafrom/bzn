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
  STATEMENT = <<~SQL.freeze
    SELECT f.product_id, p.remote_id as remote_id, f.created_at, f.sizes
    FROM hourly_facts f
    INNER JOIN unnest('{%{ids}}'::int[]) WITH ORDINALITY t(id, ord) USING (id)
    LEFT JOIN products p ON f.product_id = p.id
    ORDER BY t.ord
  SQL

  belongs_to :product

  def self.pluck_fields_for_report(ids)
    connection.execute(STATEMENT % { ids: ids.join(',') })
  end
end
