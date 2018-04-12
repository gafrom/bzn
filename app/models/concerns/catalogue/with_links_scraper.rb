module Catalogue::WithLinksScraper
  PAGE_LIMIT = 100
  SCRAPER_BATCH_SIZE = 500

  private

  def scrape_links(rel_urls = nil, start_page: 0, paginate: true)
    return unless obsolete? :links

    rel_urls = [rel_urls] unless rel_urls.respond_to? :each

    links_count = 0
    pages_count = 0
    CSV.open path_to_file(:links), 'wb' do |file|
      rel_urls.each do |rel_url|
        abs_url = "#{supplier.host}#{rel_url}"
        puts "Updating links from #{abs_url}... "
        param_prifix = abs_url.include?('?') ? '&' : '?'

        start_page.upto PAGE_LIMIT do |num|
          paginated_url = "#{abs_url}#{param_prifix}page=#{num}"

          print "Scraping #{paginated_url} ..."
          links = yield Nokogiri::HTML(open(paginated_url).read)
          puts ' Done ✅'
          break if links.blank?

          links.each { |url| file << [url] }
          links_count += links.size
          pages_count += 1

          break unless paginate
        end
      end
    end

    puts "Finished. Scraped #{pages_count} pages, found #{links_count} links."
  end

  def process_links
    CSV.foreach(path_to_file(:links)).each_slice(SCRAPER_BATCH_SIZE) do |batch_of_links|
      puts '[NEW BATCH] Garbage collected and started processing new batch ...'
      batch_of_links.each do |link|
        url = link.first
        product = Product.find_or_initialize_by remote_key: url, supplier: supplier

        @pool.run { synchronize url, product }
        # synchronize url, product
      end

      @pool.await_completion
      GC.start
    end

    hide_removed_products

    puts "Created: #{@created_count}\n" \
         "Updated: #{@updated_count}\n" \
         "Skipped: #{@skipped_count}\n" \
         "Hidden: #{@hidden_count}\n" \
         "Failures: #{@failures_count}"
  end
end
