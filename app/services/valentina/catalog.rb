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

      desc = info.css('>.product-body').first.inner_html
                 .strip.gsub('strong>', 'b>').gsub(':</b>', '</b>')
      info.css('>.field .field-item').each do |item|
        label = item.css('.field-label-inline-first').first.text.gsub(' ', ' ').strip
        label = label[0..-2] if label[-1] == ':'
        value = item.xpath('text()').text.strip
        value << 'см' if label =~ /длина/i && value !~ /см/

        desc << "<p><b>#{label}</b>#{value}</p>"
      end
      attrs[:description] = desc

      attrs[:color] = info.css('>.table_product tbody .rowcolor').first&.text
      attrs[:color_ids] = @colorizer.ids attrs[:color] if attrs[:color]

      image_div = all_info.css('.product-image').first
      attrs[:images] =
        image_div.css('>div a:last-of-type')
                 .map { |link| link.attr('href').split(supplier.host).second.split('?').first }

      attrs[:is_available] = attrs[:price] > 0 && attrs[:sizes].any?
      attrs[:compare_price] = attrs[:price] * 2
      # no collection available at the web site

      attrs
    end
  end
end
