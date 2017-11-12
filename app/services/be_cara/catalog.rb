require 'open-uri'
require 'csv'

module BeCara
  class Catalog < ::Catalog
    include Catalogue::WithLinksScraper
    include Catalogue::WithSupplier
    include Catalogue::WithFile
    include Catalogue::WithTrackedProductUpdates

    def sync
      update_file price: '/price'

      scrape_links '/catalog/search' do |page|
        page.css('.view-content .field-content>a:first-child')
            .map { |a_node| a_node.attr('href') }
      end

      process_links
    end

    private

    def price_data
      @price_data ||= begin
        @price_data = {}

        CSV.new(file_contents(:price)).each do |row|
          url, sizes, price = row
          @price_data[url] = { sizes: sizes.split(', '), price: price.to_i }
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

      desc = info.css('.product_attributes>*').map do |desc_node|
        if desc_node.css('>.label').first.text == 'Цвет:'
          attrs[:color] = desc_node.css('>.content').first.text
          attrs[:color_ids] = @colorizer.ids attrs[:color]
        end
        "<p>#{desc_node.content.to_html}</p>"
      end
      attrs[:description] = "<div>#{desc}</div>"

      attrs[:images] =
        page.css('.content>.left-side .cloud-zoom-gallery-thumbs>a')
            .map { |link| link.attr('href').split(supplier.host).second.split('?').first }

      attrs[:is_available] = attrs[:price] > 0
      attrs[:compare_price] = attrs[:price] * 2
      # no collection available at the web site

      byebug
      attrs
    end

  end
end
