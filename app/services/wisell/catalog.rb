require 'open-uri'
require 'csv'

module Wisell
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    API_URL = {
      clothes: '/bitrix/catalog_export/yandex_wisell_without_models_opt.php',
      accessories: '/bitrix/catalog_export/yandex_wisell_bijou_opt.php'
    }.freeze

    def sync
      update if obsolete?
      API_URL.keys.each { |type| sync_with_file_products_of type }

      @pool.await_completion
      hide_removed_products

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def sync_with_file_products_of(type)
      content = File.open(path_to_links_file(type)).read

      Supplier # workaround to ActiveRecord bug `load_missing_constant'
      Nokogiri::XML(content).css('offer').each do |offer|
        @pool.run { synchronize_with offer }
        # synchronize_with offer, type
      end
    end

    def update
      API_URL.each do |key, url|
        uri = URI "#{supplier.host}/#{url}"
        print "Updating #{key} catalog file from #{uri}... "
        IO.copy_stream open(uri), path_to_links_file(key)
        puts 'Done'
      end
    end

    def path_to_links_file(key = API_URL.keys.first)
      Rails.root.join 'storage', "#{self.class.name.underscore}.#{key}.links"
    end

    def url_from(offer)
      offer.css('url').first.text.split(supplier_host).second
    end

    def product_attributes_from(offer, type)
      attrs = {}
      attrs[:remote_key] = offer.attr('id')
      attrs[:title] = offer.attr('name')
      
      categorizer = Categorizer.new offer.css('categoryId').first&.text.to_i, attrs[:title]
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

      size_node = offer.css('param[name="Размер"]').first
      if size_node
        attrs[:sizes] = size_node.text.split(', ')
      elsif attrs[:category_id] == 13
        attrs[:sizes] = ['unified']
      end

      attrs[:is_available] = offer.attr('available').to_s == 'true'
      attrs[:compare_price] = attrs[:price] * 2
      attrs[:color] = offer.css('param[name="Цвет"]').first&.text
      attrs[:color_ids] = @colorizer.ids attrs[:color] if attrs[:color].present?
      attrs[:url] = url_from offer

    # rescue NoMethodError
    #   byebug
      attrs
    end
  end
end
