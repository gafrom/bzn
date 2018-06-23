module Catalogue::WithSupplierClassMethods
  def supplier
    @supplier ||= begin
      supplier_slug = self.name.split('::').first
      @supplier = Supplier.find_by name: supplier_slug
    end
  end
end