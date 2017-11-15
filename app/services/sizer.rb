class Sizer
  PERMITTED = (36..66).step(2).to_a.freeze
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
  DASH = '-'.freeze

  def initialize(product = nil)
    @product = product
  end

  def russian(size)
    subsizes = size.split DASH

    subsizes.map do |subsize|
      next subsize if permitted.include? subsize.to_i
      common[subsize] || raise(NotImplementedError, error_msg(subsize))
    end.join DASH
  end

  private

  def permitted
    self.class::PERMITTED
  end

  def common
    self.class::COMMON
  end

  def error_msg(size)
    "[SIZE ERROR] Unpermitted size '#{size}' for product #{@product.full_url}"
  end
end
