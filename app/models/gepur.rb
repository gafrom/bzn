module Gepur
  def self.table_name_prefix
    'gepur_'
  end

  def self.supplier
    @supplier ||= Supplier.find_or_create_by! name: self.name
  end
end
