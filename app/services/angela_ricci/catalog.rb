require 'open-uri'
require 'csv'

module AngelaRicci
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    def sync
      update_links if obsolete?
      process_links
    end

    private

    def process_links
      @initial_processing = true
      CSV.foreach path_to_links_file do |link_data|
        url = "#{supplier.host}#{link_data.first}"
        next process_single_category_link url if @initial_processing

        @pool.run { process_single_category_link url }
      end

      @pool.await_completion
      hide_removed_products

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    def process_single_category_link(url)
      @initial_processing = false
      index_page = Nokogiri::HTML open(url).read
      products_attrs = products_attributes_from index_page
      products_attrs.each { |attrs| update_product attrs }
    end

    def update_links
      print "Updating links from #{supplier.host}... "
      CSV.open path_to_links_file, 'wb' do |file|
        links = extract_links_from open(supplier.host).read
        links.each { |url| file << [url] }
      end
      puts 'Done'
    end

    def extract_links_from(content)
      Nokogiri::HTML(content).css('.content .catalog_item>a:first-child').map do |a_node|
        a_node.attr('href')
      end.compact
    end

    def products_attributes_from(page)
      page.css('.content table.catalog').map do |item|
        begin
          attrs = {}
          info = item.css('td.catalogtext').first

          attrs[:title] = info.css('>.cataloginner2 h2').first.text
                              .gsub('«', '').gsub('»', '')
          attrs[:images] = item.css('a.goods_photo').inject([]) do |s, a_node|
            ref = a_node.attr('href')
            ref =~ /youtube/i ? s : (s << ref)
          end

          attrs[:is_available] = info.css('>.cataloginner2 .catalogparam>td')
                                     .any? { |td| td.text == 'Есть в наличии!' }

          attrs[:sizes] = info.css('>.cataloginner2 .catalogparam>td.sizes')
                              .first.text.split(', ')
          attrs[:price] = info.css('>.cataloginner2 .catalogparam>td>.price>span')
                              .first.text.to_i
          categorizer = Categorizer.new attrs[:title]
          # Still do not know what the art is, but just in case
          # attrs[:remote_key] = item.css('td>div>a.goods_photo').first.attr('art')
          attrs[:remote_key] = "#{categorizer.key} #{categorizer.code}"
          attrs[:collection] = categorizer.collection
          attrs[:category_id] = categorizer.category_id
          attrs[:description] = info.css('>.good_description').first.to_html
                                    .gsub("\r", '')
                                    .gsub("\t", ' ')
                                    .squeeze("\n").squeeze(' ')
          attrs[:compare_price] = attrs[:price] * 2
          # no color available at the web site
          attrs
        rescue NotImplementedError, NoMethodError => ex
          log_failure_for attrs[:title], ex.message
          nil
        end
      end.compact
    end
  end
end
