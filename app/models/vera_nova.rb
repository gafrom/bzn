module VeraNova
  PRODUCTS_URL_BASE = 'http://veranova.ru'.freeze

  def self.table_name_prefix
    'vera_nova_'
  end

  def self.supplier
    @supplier ||= Supplier.find_or_create_by! name: self.name do |supplier|
      supplier.host = PRODUCTS_URL_BASE
    end
  end
end
