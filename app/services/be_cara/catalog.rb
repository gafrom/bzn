module BeCara
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates

    NUM_THREADS = 8

    LINKS_URLS = %w[/catalog/bluzy
                    /catalog/bluzy-yubki
                    /catalog/platya
                    /catalog/yubki
                    /catalog/osen-zima
                    /catalog/rasprodazha
                    /catalog/zapasnaya]

    def sync
      update_file price: '/price'

      scrape_links LINKS_URLS do |page|
        page.css('.view-content .field-content>a:first-child')
            .map { |a_node| a_node.attr('href') }
      end

      process_links
      update_properties_by_title
    end

    private

    def price_data
      @price_data ||= begin
        @price_data = {}

        contents = file_contents(:price, encoding: 'Windows-1251')
                                        .gsub("\r", "\n").gsub('"', '')

        CSV.parse(contents, col_sep: ';') do |row|
          url, sizes, price = row
          @price_data[url] = { sizes: sizes.split(', '), price: price.to_i } if price.to_i > 0
        end

        @price_data
      end
    end

    def product_attributes_from(page)
      attrs = {}
      info = page.css('.content>.right-side')
      attrs[:title] = info.css('>h1').first.text.strip
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title

      data = price_data[attrs[:title]]
      attrs[:price] = data[:price]
      attrs[:sizes] = data[:sizes]

      desc = ''
      previous_label = nil
      values = []
      info.css('.product_attributes>div').each do |desc_node|
        label = desc_node.css('>.label').first&.text
        if label == 'Цвет:'
          color = desc_node.css('>.content').first.text.strip
          if color.present?
            attrs[:color] = color
            attrs[:color_ids] = @colorizer.ids color
          end
        end

        text = desc_node.css('>p').first
        desc << "<p>#{text.content}</p>" if text

        label, value = desc_node.css('>div').map(&:content)
        if label.present? 
          label = label[0..-2] if label[-1] == ':'
          previous_label ||= label
          if values.any?
            desc << "<p><b>#{previous_label}</b>#{values.join(', ')}</p>"
            previous_label = label
            values = []
          end
        end
        if value.present?
          value = value[0..-2] if value[-1] == ':'
          values << value
        end
      end
      desc << "<p><b>#{previous_label}</b>#{values.join(', ')}</p>" if values.any?
      attrs[:description] = desc

      attrs[:images] =
        page.css('.content>.left-side .cloud-zoom-gallery-thumbs>a')
            .map { |link| link.attr('href').split(supplier.host).second.split('?').first }

      attrs[:is_available] = attrs[:price] > 0 && attrs[:sizes].any?
      attrs[:compare_price] = attrs[:price] * 2
      # no collection available at the web site

      attrs
    end

  end
end
