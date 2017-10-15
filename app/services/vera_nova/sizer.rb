module VeraNova
  class Sizer
    PERMITTED = (38..66).step(2).to_a.freeze

    def initialize(product = nil)
      @product = product
    end

    def russian(size)
      return size if PERMITTED.include? size.to_i
      raise NotImplementedError, "[SIZE ERROR] Not permitted (new): '#{size}'"
    end
  end
end
