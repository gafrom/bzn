module Catalogue::WithLinksScraper
  PAGE_LIMIT = 100

  private

  def scrape_links(page_url, first_page_num = 0)
    url = "#{supplier.host}#{page_url}"
    puts "Updating links from #{url}... "

    links_count = 0
    pages_count = 0
    CSV.open path_to_file(:links), 'wb' do |file|
      first_page_num.upto PAGE_LIMIT do |num|
        full_url = "#{url}?page=#{num}"
        print "Scraping #{full_url} ..."
        content = open(full_url).read

        links = yield Nokogiri::HTML(content)
        puts ' Done'
        break if links.blank?

        links.each { |url| file << [url] }
        links_count += links.size
        pages_count += 1
      end
    end

    puts "Finished. Scraped #{pages_count} pages, found #{links_count} links."
  end

  def process_links
    CSV.foreach path_to_file(:links) do |link|
      url = link.first
      product = Product.find_or_initialize_by remote_key: url, supplier: supplier

      # @pool.run { synchronize url, product }
      synchronize url, product
    end

    # @pool.await_completion
    hide_removed_products

    puts "Created: #{@created_count}\n" \
         "Updated: #{@updated_count}\n" \
         "Skipped: #{@skipped_count}\n" \
         "Hidden: #{@hidden_count}\n" \
         "Failures: #{@failures_count}"
  end
end
