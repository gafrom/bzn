module Wisell
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithTrackedProductUpdates

    def sync
      update_files clothes: '/bitrix/catalog_export/yandex_wisell_without_models_opt.php',
                   accessories: '/bitrix/catalog_export/yandex_wisell_bijou_opt.php'

      file_contents do |content|
        Nokogiri::XML(content).css('offer').each do |offer|
          @pool.run { synchronize_with offer }
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

    def product_attributes_from(offer)
      attrs = {}
      attrs[:remote_key] = offer.attr('id')
      attrs[:title] = offer.attr('name')
      
      categorizer = Categorizer.new remote_id: offer.css('categoryId').first&.text,
                                    title: attrs[:title]
      attrs[:category_id] = categorizer.category_id
      attrs[:price] = offer.css('price').first.text.to_i

      desc = "<p>#{offer.css('description').first.text}</p>"
      temp = offer.css('country_of_origin').first
      desc << "<p><b>Страна производства</b>#{temp.text}</p>" if temp
      ['Материал', 'Ткань', 'Длина размера'].each do |param|
        temp = offer.css("param[name='#{param}']").first
        desc << "<p><b>#{param}</b>#{temp.text}</p>" if temp
      end
      attrs[:description] = desc

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

      attrs
    end
  end
end
