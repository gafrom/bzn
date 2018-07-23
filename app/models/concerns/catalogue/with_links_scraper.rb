module Catalogue::WithLinksScraper
  PAGE_LIMIT = 300

  private

  def scrape_links(rel_urls = nil, to: :disk, format: :html, start_page: 1, paginate: true, &block)
    return if to == :disk && !obsolete?(:links)

    conn = format == :json && Faraday.new(url: supplier.host) do |conn|
      conn.headers.merge! self.class::INDEX_PAGE_HEADERS
      # conn.response :logger
      conn.adapter  :net_http
    end

    rel_urls = [rel_urls] unless rel_urls.respond_to? :each

    links_count = 0
    pages_count = 0
    CSV.open path_to_file(:links), 'wb' do |file|
      rel_urls.each do |rel_url|
        abs_url = "#{supplier.host}#{rel_url}"
        @logger.info "Checking out #{abs_url}... "
        param_prifix = abs_url.include?('?') ? '&' : '?'

        start_page.upto PAGE_LIMIT do |num|

          links = case format
                  when :html
                    links_from_a_single_page "#{abs_url}#{param_prifix}page=#{num}", block
                  when :json
                    ref_url = num > 1 ? "#{abs_url}#{param_prifix}page=#{num - 1}" : supplier.host
                    links_from_json "#{rel_url}#{param_prifix}page=#{num}", ref_url, conn, block
                  end

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

    @logger.info "Finished. Scraped #{pages_count} pages, found #{links_count} links."
  end

  def links_from_json(rel_url, ref_url, conn, block)
    @logger.info "Scraping JSON from #{rel_url} ..."
    response = conn.post rel_url, nil, Referer: ref_url

    if response.success?
      block[JSON.parse(response.body)]
      true
    else
      puts " Got #{response.status} - treating it as the end of the journey. ✅"
      nil
    end
  rescue JSON::ParserError => error
    @logger.info " Got wrong JSON (#{error.message}) - treating it as the end of the journey. ✅"
    nil
  end

  def links_from_a_single_page(paginated_url, block)
    @logger.info "Scraping #{paginated_url} ..."
    links = block[Nokogiri::HTML(open(paginated_url).read)]
    links
  rescue OpenURI::HTTPError => error
    response = error.io
    @logger.info " Got #{response.status.first} - treating it as the end of the journey. ✅"
    nil
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

    @logger.info "Created: #{@created_count}\n" \
                 "Updated: #{@updated_count}\n" \
                 "Skipped: #{@skipped_count}\n" \
                 "Hidden: #{@hidden_count}\n" \
                 "Failures: #{@failures_count}"
  end
end
