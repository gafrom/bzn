class SizeArray < Array
  def initialize(data, product)
    @product = product
    super data
  end

  def russian
    sizer = @product.supplier.domain::Sizer.new @product
    map { |size| sizer.russian size }
  end

  def available
    return unless @product.is_available?
    join ', '
  end
end
