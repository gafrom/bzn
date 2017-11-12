require 'open-uri'
require 'csv'

module VeraNova
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    LINKS_LIST_URL = URI 'http://veranova.ru/sitemap-product.xml'

    def initialize(*args)
      super
      @success_count = 0
    end

    def sync
      update_links if obsolete?
      process_links
    end

    private

    def process_links
      CSV.foreach path_to_links_file do |link|
        url, modified_at = link
        product = Product.find_or_initialize_by remote_key: url, supplier: supplier
        next skip url if fresh? product, modified_at

        @pool.run { synchronize url, product }
      end

      @pool.await_completion
      hide_removed_products

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    def product_attributes_from(page)
      attrs = {}
      attrs[:title] = page.css('[itemprop="name"]').first.text
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title
      attrs[:price] = page.css('#formated_price').first.attr('price').to_i
      desc = page.css('[itemprop="model"]').first.text
      attrs[:description] = desc.blank? ? '' : "<p class='fabric'>Состав: #{desc}</p>"
      attrs[:description] << page.css('#tab-description').first.to_html.gsub("\n", ' ').squeeze(' ')
      attrs[:images] = page.css('#one-image>.item>img')
                           .map { |img| img.attr('src').split(supplier.host).second }
      attrs[:sizes] = page.css('#product .owq-name').map { |el| el.text }
      attrs[:is_available] = attrs[:price] > 0
      attrs[:compare_price] = attrs[:price] * 2
      # no color available at the web site
      # no collection available at the web site
      attrs
    end

    def update_links
      print "Updating links from #{LINKS_LIST_URL}... "
      CSV.open path_to_links_file, 'wb' do |file|
        links = extract_links open(LINKS_LIST_URL).read
        links.each { |url, modified_at| file << [url, modified_at] }
      end
      puts 'Done'
    end

    def fresh?(product, modified_at_as_string)
      updated_at = product.updated_at
      updated_at && updated_at > modified_at_as_string.to_date
    end

    def extract_links(content)
      Nokogiri::XML(content).css('url').inject({}) do |links, node|
        url = node.css('loc').first.text.split(supplier.host).last
        modified_at = node.css('lastmod').first.text.to_date
        log_failure_for url, '[SITEMAP PARSING]' unless url && modified_at

        links.merge! url => modified_at
      end
    end
  end
end
