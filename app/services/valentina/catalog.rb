module Valentina
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates

    NUM_THREADS = 8

    def sync
      scrape_links '/catalog' do |page|
        page.css('.view-content .views-field:first-child>.field-content>a:first-child')
            .map { |a_node| a_node.attr('href') }
      end

      process_links
      update_properties_by_title
    end

    private

    def product_attributes_from(page)
      attrs = {}
      all_info = page.css('#content>.article').first
      attrs[:title] = all_info.css('h1').first.text.strip
      attrs[:title].prepend 'Юбка ' if attrs[:title] =~ /\AЭрика/
      attrs[:title].prepend 'Колготки ' if attrs[:title] =~ /\A(Glamour|Sisi)/
      attrs[:title].prepend 'Ремень ' if attrs[:title] =~ /\AА\/(РБ1|РЦ-3)/
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title

      info = all_info.css('.product-decr').first
      attrs[:price] = info.css('.uc-price-product-display-formprod')
                          .first.text.gsub(/[^\d]/, '').to_i
      attrs[:sizes] = info.css('>.table_product thead .cellname')
                          .map { |size_node| size_node.text.strip }
      size_desc = ''
      if attrs[:category_id] == 15
        size_desc = "<p><b>Размер</b>#{attrs[:sizes].join(', ')}</p>" if attrs[:sizes].any?
        attrs[:sizes] = ['unified']
      end

      desc = info.css('>.product-body').first.inner_html
                 .strip.gsub('strong>', 'b>').gsub(':</b>', '</b>')
      info.css('>.field .field-item').each do |item|
        label = item.css('.field-label-inline-first').first.text.gsub(' ', ' ').strip
        label = label[0..-2] if label[-1] == ':'
        value = item.xpath('text()').text.strip

        if label =~ /длина/i
          length = value.to_i
          if length > 0
            attrs[:length] = length
            attrs[:properties] = [Property.from_length(length)] if attrs[:category_id] == 3
          end
          value << 'см' if value !~ /см/
        end

        desc << "<p><b>#{label}</b>#{value}</p>"
      end
      desc << size_desc
      attrs[:description] = desc

      color = info.css('>.table_product tbody .rowcolor').first&.text&.strip
      if color.present?
        attrs[:color] = color
        attrs[:color_ids] = @colorizer.ids color
      end

      image_div = all_info.css('.product-image').first
      attrs[:images] =
        image_div.css('>div a:last-of-type')
                 .map do |link|
                    href = link.attr('href')
                    next if href =~ /no_photo/

                    href.split(supplier.host).second.split('?').first
                  end.compact

      attrs[:is_available] =
        attrs[:price] > 0 && attrs[:sizes].any? && attrs[:images].any?
      attrs[:compare_price] = attrs[:price] * 2
      # no collection available at the web site

      attrs
    end
  end
end
