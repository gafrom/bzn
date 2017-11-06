require 'open-uri'
require 'csv'

module Charutti
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    SITEMAP_URL = '/sitemap.xml'.freeze

    def sync
      update_links if obsolete?
      process_links
    end

    private

    def process_links
      CSV.foreach path_to_links_file do |link_data|
        url, modified_at = link_data
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
      node = page.css('#content .pane-content')
      info = node.css('.b-element_content')

      attrs = {}
      attrs[:title] = info.css('.b-name_element').first.text.strip
      attrs[:category] = Categorizer.new.from_title attrs[:title]
      attrs[:price] = info.css('.b-element_price').first.text.delete(' ').to_i
      attrs[:sizes] = info.css('.add-action-form>.b-size_block .b-size_block__list_li_title')
                          .map { |el| el.text }      
      desc_node = info.css('.block_description_property')
      desc_node.css('.js-quest-open').remove
      attrs[:description] = desc_node.to_html
                                     .squeeze(' ')
                                     .gsub(/>[\r\n\s]+</, '><')
                                     .squeeze("\t")
      attrs[:images] = node.css('.view-content .tovar-big-image>a')
                           .map { |a_node| a_node.attr('href') }
      attrs[:is_available] = attrs[:price] > 0
      attrs[:compare_price] = attrs[:price] * 2
      # no color available at the web site
      # no collection available at the web site
      attrs
    end

    def update_links
      print "Updating links from #{supplier.host}... "
      CSV.open path_to_links_file, 'wb' do |file|
        links = extract_links_from open("#{supplier.host}#{SITEMAP_URL}").read
        links.each { |url, last_modified_at| file << [url, last_modified_at] }
      end
      puts 'Done'
    end

    def extract_links_from(content)
      pattern = /\A\/(news\/.*|content\/.*|catalog\/.*|new-sale\/.*|sale\/.*)?\Z/
      Nokogiri::XML(content).css('url').inject({}) do |links, node|
        url = node.css('loc').first.text.split(supplier.host).last
        modified_at = node.css('lastmod').first.text.to_date
        if url && modified_at
          next links if url =~ pattern
          links.merge url => modified_at
        else
          log_failure_for url, '[SITEMAP PARSING]'
          links
        end
      end
    end

  end
end
