class ApplicationRecord < ActiveRecord::Base
  STATEMENT_TO_GET_SIZES = %{SELECT nspname || '.' || relname AS "relation",    pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size"  FROM pg_class C  LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)  WHERE nspname NOT IN ('pg_catalog', 'information_schema')    AND C.relkind <> 'i'    AND nspname !~ '^pg_toast'  ORDER BY pg_total_relation_size(C.oid) DESC  LIMIT 15; }

  self.abstract_class = true

  def self.fetch_table_sizes
    connection.execute(STATEMENT_TO_GET_SIZES).to_a
  end
end
