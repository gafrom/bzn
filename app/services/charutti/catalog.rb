require 'open-uri'
require 'csv'

module Charutti
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    SITEMAP_URL = '/sitemap.xml'.freeze

    def sync
      ensure_links_are_fresh
      # process_links
    end

    private

    def update_links
      print "Updating links from #{supplier.host}... "
      CSV.open path_to_links_file, 'wb' do |file|
        links = extract_links_from open("#{supplier.host}#{SITEMAP_URL}").read
        links.each { |url| file << [url] }
      end
      puts 'Done'
    end

    # def extract_links_from(content)
    #   Nokogiri::XML(content).css('.katalog-image>a.ajax-link').map do |a_node|
    #     a_node.attr('href')
    #   end.compact
    # end


    def extract_links_from(content)
      pattern = /\A\/(news\/.*|content\/.*|catalog\/.*|\/)\Z/
      Nokogiri::XML(content).css('url').inject({}) do |links, node|
        url = node.css('loc').first.text.split(supplier.host).last
        modified_at = node.css('lastmod').first.text.to_date
        if url && modified_at
          links.merge url => modified_at unless url =~ pattern
        else
          log_failure_for url, '[SITEMAP PARSING]'
          links
        end
      end.compact
    end

  end
end
