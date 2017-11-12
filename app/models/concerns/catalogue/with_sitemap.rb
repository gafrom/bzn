module Catalogue::WithSitemap
  private

  def update_sitemap_links(excl_pattern = nil)
    print "Updating links from #{supplier.host}... "
    CSV.open path_to_file, 'wb' do |file|
      content = open("#{supplier.host}#{self.class::SITEMAP_URL}").read
      links = extract_sitemap_links content, excl_pattern

      links.each do |url, last_modified_at|
        short_url = url.split(supplier.host).last
        next unless short_url =~ /\A\/production/
        file << [short_url, last_modified_at]
      end
    end
    puts 'Done'
  end

  def extract_sitemap_links(content, excl_pattern = nil)
    Nokogiri::XML(content).css('url').inject({}) do |links, node|
      url = node.css('loc').first.text.split(supplier.host).last
      modified_at = node.css('lastmod').first.text.to_date

      if url && modified_at
        next links if excl_pattern && url =~ excl_pattern
        links.merge! url => modified_at
      else
        log_failure_for url, '[SITEMAP PARSING]'
        links
      end
    end
  end
end
