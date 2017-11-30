module Fly
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithCatalogFile
    include Catalogue::WithTrackedProductUpdates

    NUM_THREADS = 4

    def sync
      update_file links: '/bitrix/catalog_export/yandex_sliza.php'

      offers = Nokogiri::XML(file_contents(:links)).css('offer')
      grouped_offers(offers).each do |url, offers|
        @pool.run do
          sizes = offers.map { |offer| size_from offer }.compact.uniq
          synchronize_with offers.first, remote_key: url,
                                         url: url,
                                         sizes: sizes,
                                         is_available: sizes.any?
        end
      end

      @pool.await_completion
      hide_removed_products

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def grouped_offers(offers)
      result = {}
      offers.each do |offer|
        url = url_from offer
        next result[url] << offer if result[url]
        result[url] = [offer]
      end
      result
    end

    def url_from(offer)
      offer.css('url').first.text.split(supplier_host).last[/\/production\/\d+\//]
    end

    def size_from(offer)
      return unless offer.attr('available').to_s == 'true'
      size_node = offer.css('param[name="Размер"]').first
      return 'unified' if !size_node || size_node.text.blank?
      size_node.text
    end

    def product_attributes_from(offer)
      attrs = {}
      attrs[:title] = offer.css('name').first.text.gsub(/\s\(\d+\)/, '')

      categorizer = Categorizer.new title: attrs[:title],
                                    remote_id: offer.css('categoryId').map(&:text)
      attrs[:category_id] = categorizer.category_id
      attrs[:price] = offer.css('price').first.text.to_i

      desc = "<p>#{offer.css('description').first.text}</p>"
      temp = offer.css('country_of_origin').first
      desc << "<p><b>Страна производства</b> #{temp.text}</p>" if temp
      ['Состав', 'Ткань', 'Длина размера', 'Производитель'].each do |param|
        temp = offer.css("param[name='#{param}']").first
        desc << "<p><b>#{param}</b>#{temp.text}</p>" if temp
      end
      attrs[:description] = desc

      attrs[:images] = offer.css('picture')
                            .map { |pic| pic.text.split(supplier_host).second }
      attrs[:compare_price] = attrs[:price] * 2
      attrs[:color] = offer.css('param[name="Цвет"]').first&.text
      attrs[:color_ids] = @colorizer.ids attrs[:color] if attrs[:color].present?

      attrs
    end
  end
end
