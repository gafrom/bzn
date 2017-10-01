module Gepur
  class Sizer
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
      'ун'  => 'единый'
    }.freeze
    PERMYAKOVA = {
      # plus sizes
      'xl'  => '52',
      '2xl' => '54',
      'xxl' => '54',
      '3xl' => '56',
      '4xl' => '58'
    }.freeze
    DASH = '-'.freeze

    def initialize(product)
      @product_collection = product.collection
    end

    def russian(size)
      subsizes = size.split DASH

      subsizes.map do |subsize|
        case subsize
        # shoes, kids and bikini sizes
        when /\A([\d.,]+|75B|80C)\Z/i then subsize
        # common sizes
        else numeric subsize.downcase
        end
      end.join DASH
    end

    private

    def numeric(size)
      schedule = permyakova? ? PERMYAKOVA : COMMON
      schedule.fetch size
    end

    def permyakova?
      @product_collection =~ /пермякова/i
    end
  end
end
