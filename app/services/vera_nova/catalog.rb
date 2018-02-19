module VeraNova
  class Catalog < ::Catalog
    include Catalogue::Authenticatable
    include Catalogue::WithFile
    include Catalogue::WithSitemap
    include Catalogue::WithTrackedProductUpdates

    def initialize(*args)
      super
      @success_count = 0
    end

    def sync
      login '/index.php?route=account/login', email: ENV.fetch('VERANOVA_EMAIL'),
                                              password: ENV.fetch('VERANOVA_PASSWORD')
      extract_sitemap_links '/sitemap-product.xml'
      process_links
    end

    private

    def product_attributes_from(page)
      attrs = {}
      attrs[:title] = page.css('[itemprop="name"]').first.text
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title

      price_node = page.css('#formated_special').first || page.css('#formated_price').first
      attrs[:price] = price_node.attr('price').to_i

      desc = page.css('[itemprop="model"]').first.text
      attrs[:description] = desc.blank? ? '' : "<p><b>Состав</b>#{desc}</p>"
      attrs[:description] << page.css('#tab-description').first.to_html.gsub("\n", ' ').squeeze(' ')
      attrs[:images] = page.css('#one-image>.item>img')
                           .map { |img| img.attr('src').split(supplier.host).second }
      attrs[:sizes] = page.css('#product .owq-name').map { |el| el.text }
      attrs[:is_available] = attrs[:price] > 0
      attrs[:compare_price] = attrs[:price] * 2

      raw_length = page.css('.product-info .econom').first
      if raw_length
        length = raw_length.text[/длина[^\d]+(\d+)[^\d]*см/i, 1].to_i
        if length > 0
          attrs[:length] = length
          attrs[:properties] = [Property.from_length(length)]
        end
      end

      # no color available at the web site
      # no collection available at the web site
      attrs
    end
  end
end
