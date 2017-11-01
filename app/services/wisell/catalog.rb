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
      sync_products_with_file

      @pool.await_completion

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def sync_products_with_file
      content = File.open(path_to_links_file).read

      Supplier # workaround to ActiveRecord bug `load_missing_constant'
      Nokogiri::XML(content).css('offer').each do |offer|
        @pool.run { synchronize_with offer }
      end
    end

    def update
      uri = URI "#{supplier.host}/#{CLOTHES_API_URL}"
      print "Updating catalog file from #{uri}... "
      IO.copy_stream open(uri), path_to_links_file
      puts 'Done'
    end

    def url_from(offer)
      offer.css('url').first.text.split(supplier_host).second
    end

    def product_attributes_from(offer)
      attrs = {}
      attrs[:remote_key] = offer.attr('id')
      attrs[:title] = offer.attr('name')
      categorizer = Categorizer.new offer.css('categoryId').first.text.to_i, attrs[:title]
      attrs[:category_id] = categorizer.category_id
      attrs[:price] = offer.css('price').first.text.to_i

      desc = "<p>#{offer.css('description').first.text}</p>"
      temp = offer.css('country_of_origin').first
      desc << "<p>Страна производства #{temp.text}</p>" if temp
      ['Материал', 'Ткань', 'Длина размера'].each do |param|
        temp = offer.css("param[name='#{param}']").first
        desc << "<p>#{param} <span>#{temp.text}</span></p>" if temp
      end

      attrs[:description] = "<div>#{desc}</div>"
      attrs[:images] = offer.css('picture')
                            .map { |pic| pic.text.split(supplier_host).second }
      attrs[:sizes] = offer.css('param[name="Размер"]').first.text.split(', ')
      attrs[:is_available] = offer.attr('available').to_s == 'true'
      attrs[:compare_price] = attrs[:price] * 2
      attrs[:color] = offer.css('param[name="Цвет"]').first&.text
      attrs[:url] = url_from offer

      attrs
    end
  end
end
