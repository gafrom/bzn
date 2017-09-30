module Gepur
  PRODUCTS_URL_BASE = 'https://gepur.com/product/'.freeze

  def self.table_name_prefix
    'gepur_'
  end

  def self.supplier
    @supplier ||= Supplier.find_or_create_by! name: self.name do |supplier|
      supplier.host = PRODUCTS_URL_BASE
    end
  end
end
