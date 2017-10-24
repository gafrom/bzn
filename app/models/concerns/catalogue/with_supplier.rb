module Catalogue::WithSupplier
  def supplier
    @supplier ||= begin
      supplier_slug = self.class.name.split('::').first
      @supplier = Supplier.find_by name: supplier_slug
      return @supplier if @supplier

      abort "Please specify supplier's HOST. Aborted" unless @supplier_host

      @supplier = Supplier.create name: supplier_slug, host: @supplier_host
    end
  end
end
