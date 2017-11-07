class Sizer
  PERMITTED = (38..66).step(2).to_a.freeze
  COMMON = {
    # common sizes
    'xs'  => '40',
    's'   => '42',
    'm'   => '44',
    'l'   => '46',
    'xl'  => '48',
    '2xl' => '50',
    'xxl' => '50',
    '3xl' => '52',
    '4xl' => '54',
    '5xl' => '56',
    '6xl' => '58',
    'unified'  => 'единый'
  }.freeze

  def initialize(product = nil)
    @product = product
  end

  def russian(size)
    return size if permitted.include? size.to_i
    return common[size] if common[size]

    error_msg = "[SIZE ERROR] Not permitted size '#{size}' for product #{@product.full_url}"
    raise NotImplementedError, error_msg
  end

  private

  def permitted
    self.class::PERMITTED
  end

  def common
    self.class::COMMON
  end
end
