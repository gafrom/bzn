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

      update_properties

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

      size_node = offer.css('param[name="Размер"]').first
      if size_node
        attrs[:sizes] = size_node.text.split(', ')
      elsif attrs[:category_id] == 13
        attrs[:sizes] = ['unified']
      end
      attrs[:sizes] = correct_size_if_accessory attrs[:sizes], attrs[:category_id]

      desc = "<p>#{offer.css('description').first.text}</p>"
      temp = offer.css('country_of_origin').first
      desc << "<p><b>Страна производства</b>#{temp.text}</p>" if temp
      ['Состав', 'Ткани', 'Длина изделия'].each do |param|
        temp = offer.css("param[name='#{param}']").first
        if temp
          desc << "<p><b>#{param}</b>#{temp.text}</p>"

          if param == 'Длина изделия' && temp.text.to_i > 73 # just to exclude tops
            length = temp.text.to_i
            attrs[:length] = length
            attrs[:properties] = [Property.from_length(length)] if attrs[:category_id] == 3
          end
        end
      end
      attrs[:description] = desc

      attrs[:images] = offer.css('picture')
                            .map { |pic| pic.text.split(supplier_host).second }

      attrs[:is_available] = offer.attr('available').to_s == 'true'
      attrs[:compare_price] = attrs[:price] * 2
      color = offer.css('param[name="Цвет"]').first&.text&.strip
      if color.present?
        attrs[:color] = color
        attrs[:color_ids] = @colorizer.ids color
      end
      attrs[:url] = url_from offer

      attrs
    end
  end
end
