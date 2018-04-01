module Ajour
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithSitemap
    include Catalogue::WithTrackedProductUpdates

    NUM_THREADS = 6

    def sync
      extract_sitemap_links '/sitemap.769374.xml.gz' do |url, _|
        url =~ /\A\/magazin\/product\//
      end

      process_links
      update_properties
    end

    private

    def product_attributes_from(page)
      content = page.css('.content .textbody').first

      attrs = {}
      attrs[:title] = content.css('>h1').first.text.strip
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title
      attrs[:price] = content.css('.product-card .price').first.text
                             .delete(' ').delete(' ').to_i

      attrs[:sizes] = content.css('.product-card select.additional-cart-params>option')
                          .map { |el| el.text }
      desc = content.css('#tabs-1>p').inject('') { |s, el| s << "<p>#{el.text.strip}</p>" }

      content.css('#tabs-2 tr').map do |tr|
        label = tr.css('th').first.text.strip
        value = tr.css('td').first.text.strip
        case label
        when /размер/i
          next # no need here - because we scraped sizes above
        when /цвет/i
          if value.present?
            attrs[:color] = value
            attrs[:color_ids] = @colorizer.ids value
          end
        end

        desc << "<p><b>#{label}</b>#{value}</p>"
      end
      attrs[:description] = desc

      attrs[:images] = content.css('.product-card>.side-left a.highslide')
                              .map { |a| a.attr('href') }
      attrs[:is_available] = attrs[:price] > 0 && attrs[:sizes].any?
      attrs[:compare_price] = attrs[:price] * 2

      # no collection available at the web site
      attrs
    end
  end
end
