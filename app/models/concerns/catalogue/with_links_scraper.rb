module Catalogue::WithLinksScraper
  PAGE_LIMIT = 300

  private

  def scrape_links(rel_urls = nil, to: :disk, start_page: 1, paginate: true, &block)
    return if to == :disk && !obsolete?(:links)

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
          links = links_from_a_single_page paginated_url, block
          break if links.blank?

          case to
          when :nowhere then next
          when :db then next
          when :disk
            links.each { |url| file << [url] }
            links_count += links.size
            pages_count += 1
          end

          break unless paginate
        end
      end
    end

    puts "Finished. Scraped #{pages_count} pages, found #{links_count} links."
  end

  def links_from_a_single_page(paginated_url, block)
    print "Scraping #{paginated_url} ..."
    links = block[Nokogiri::HTML(open(paginated_url).read)]
    puts ' Done ✅'
    links
  rescue OpenURI::HTTPError => error
    response = error.io
    puts " Got #{response.status.first} - treating it as the end of the journey. ✅"
    return nil
  end

  def process_links
    CSV.foreach path_to_file(:links) do |link|
      url = link.first
      product = Product.find_or_initialize_by remote_key: url, supplier: supplier

      @pool.run { synchronize url, product }
      # synchronize url, product
    end

    @pool.await_completion
    hide_removed_products

    puts "Created: #{@created_count}\n" \
         "Updated: #{@updated_count}\n" \
         "Skipped: #{@skipped_count}\n" \
         "Hidden: #{@hidden_count}\n" \
         "Failures: #{@failures_count}"
  end
end
