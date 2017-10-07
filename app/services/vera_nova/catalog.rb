require 'open-uri'
require 'csv'

module VeraNova
  class Catalog
    HOST = 'veranova.ru'
    STALE_IN = 10.hours
    LINKS_LIST_FILE = Rails.root.join 'storage', "#{self.name.underscore}.links"
    LINKS_LIST_URL = URI 'http://veranova.ru/sitemap-product.xml'

    def initialize

    end


    def sync
      build_links_list
      parse_links
    end

    private

    def build_links_list
      ensure_directory_exists

      CSV.open LINKS_LIST_FILE, 'wb' do |file|
        links = extract_links open(LINKS_LIST_URL).read
        links.each { |url, modified_at| file << [url, modified_at] }
      end
    end

    def ensure_directory_exists
      dir = File.dirname LINKS_LIST_FILE
      Dir.mkdir dir unless File.directory? dir
    end

    def extract_links(content)
      Nokogiri::XML(content).css('url').inject({}) do |links, node|
        url = node.css('loc').first.text.split(HOST).last
        modified_at = node.css('lastmod').first.text.to_date
        log_error url unless url && modified_at

        links.merge! url => modified_at
      end
    end

    def log_error(data = nil)
      Rails.logger.error "[#{self.class.name}] #{data}"
    end
  end
end
