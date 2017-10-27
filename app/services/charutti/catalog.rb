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
