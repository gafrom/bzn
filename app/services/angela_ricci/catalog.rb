require 'open-uri'
require 'csv'

module AngelaRicci
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile

    def sync
      ensure_links_are_fresh
      # process_links
    end

    private

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
  end
end
