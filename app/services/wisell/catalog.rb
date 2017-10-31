require 'open-uri'
require 'csv'

module Wisell
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    CLOTHES_API_URL = '/bitrix/catalog_export/yandex_wisell_without_models_opt.php'.freeze
    ACCESSORIES_API_URL = '/bitrix/catalog_export/yandex_wisell_bijou_opt.php'.freeze

    def sync
      update if obsolete?
      parse

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def parse
      file = File.open(path_to_links_file).read
      categories = {}
      Nokogiri::XML(file).css('offer').each do |offer|
        attrs = product_attributes_from offer
        update_product attrs
      end
    end

    def update
      uri = URI "#{supplier.host}/#{CLOTHES_API_URL}"
      print "Updating catalog file from #{uri}... "
      IO.copy_stream open(uri), path_to_links_file
      puts 'Done'
    end

    def product_attributes_from(offer)
      attrs = {}
      attrs[:remote_key] = offer.attr('id')
      attrs[:title] = offer.attr('name')
      attrs[:category_id] = Categorizer.new(offer.css('categoryId').first.text.to_i).category_id
      attrs[:price] = offer.css('price').first.text.to_i
      desc = "<p>#{offer.css('description').first.text}</p>"
      temp = offer.css('country_of_origin').first
      desc << "<p>Страна производства #{temp.text}</p>" if temp
      temp = offer.css('param[name="Материал"]').first
      desc << "<p>Материал #{temp.text}</p>" if temp
      temp = offer.css('param[name="Ткань"]').first
      desc << "<p>Ткань #{temp.text}</p>" if temp
      temp = offer.css('param[name="Длина размера"]').first
      desc << "<p>Длина размера #{temp.text}</p>" if temp
      attrs[:description] = "<div>#{desc}</div>"
      attrs[:images] = offer.css('picture')
                            .map { |pic| pic.text.split(supplier.host).second }
      attrs[:sizes] = offer.css('param[name="Размер"]').first.text.split(', ')
      attrs[:is_available] = offer.attr('available').to_s == 'true'
      attrs[:compare_price] = attrs[:price] * 2
      attrs[:color] = offer.css('param[name="Цвет"]').first.text

      attrs
    end
  end
end
