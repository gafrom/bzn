module Catalogue::WithLinksScraper
  PAGE_LIMIT = 300

  private

  def scrape_links(rel_urls = nil, to: :disk, format: :html, start_page: 1, paginate: true, &block)
    if to == :disk
      return unless obsolete?(:links)
      # erase contents now and append later by chunks
      CSV.open path_to_file(:links), 'wb'
    end

    conn = build_json_connection if format == :json
    rel_urls = [rel_urls] unless rel_urls.respond_to? :each
    start_page = paginate ? start_page : false
    @links_count = 0
    @pages_count = 0

    rel_urls.each do |rel_url|
      abs_url = "#{supplier.host}#{rel_url}"
      @logger.info "Checking out #{abs_url}... " if paginate
      param_prifix = abs_url.include?('?') ? '&' : '?'

      if start_page
        start_page.upto PAGE_LIMIT do |num|
          links = case format
                  when :plain
                    process_single_body "#{abs_url}#{param_prifix}page=#{num}", block
                  when :html
                    process_single_html "#{abs_url}#{param_prifix}page=#{num}", block
                  when :json
                    ref_url = num > 1 ? "#{abs_url}#{param_prifix}page=#{num - 1}" : supplier.host
                    process_single_json "#{rel_url}#{param_prifix}page=#{num}", ref_url, conn, block
                  end

          @pages_count += 1
          break if links.blank?

          send "put_to_#{to}", links
          @links_count += links.size if links.respond_to? :size
        end
      else
        links = case format
                when :plain then process_single_body abs_url, block
                when :html then process_single_html abs_url, block
                when :json then process_single_json rel_url, supplier.host, conn, block
                end

        @pages_count += 1
        next if links.blank?

        send "put_to_#{to}", links
        @links_count += links.size if links.respond_to? :size
      end
    end

    exiting_message = "Finished. Scraped #{@pages_count} #{'page'.pluralize(@pages_count)}"
    exiting_message << ", found #{@links_count} links." if format == :html
    @logger.info exiting_message
  end

  def put_to_nowhere(_links)
    # do nothing
  end

  def put_to_db(_links)
    # not implemented
  end

  def put_to_disk(links)
    CSV.open path_to_file(:links), 'ab' do |file|
      links.each { |url| file << [url] }
    end
  end

  def build_json_connection
    Faraday.new(url: supplier.host) do |conn|
      conn.headers.merge! self.class::INDEX_PAGE_HEADERS
      # conn.response :logger
      conn.adapter  :net_http
    end
  end

  def process_single_json(rel_url, ref_url, conn, block)
    @logger.info "Scraping JSON from #{rel_url} ..."
    response = conn.post rel_url, nil, Referer: ref_url

    if response.success?
      block[JSON.parse(response.body)]
      true
    else
      @logger.info "Got #{response.status} - treating it as the end of the journey. ✅"
      nil
    end
  rescue JSON::ParserError => error
    @logger.info "Got wrong JSON (#{error.message}) - treating it as the end of the journey. ✅"
    nil
  end

  def process_single_body(paginated_url, block)
    @logger.info "Scraping body from #{paginated_url} ..."
    body = open(paginated_url).read
    block[body]
    true
  rescue SocketError, Net::ReadTimeout, Net::OpenTimeout => ex
    retry_count = (retry_count || 0) + 1

    if retry_count >= 5
      log_failure_for paginated_url, ex.message
      nil
    else
      sleep_time = 1.8 ** (retry_count - 1)
      @logger.warn "[PROCESS_SINGLE_BODY] #{ex.message}. "\
                   "Retry ##{retry_count} in #{sleep_time} seconds ..."
      sleep sleep_time
      retry
    end
  rescue OpenURI::HTTPError => error
    response = error.io
    @logger.info " Got #{response.status.first} - treating it as the end of the journey. ✅"
    nil
  rescue => ex
    @logger.error "[PROCESS_SINGLE_BODY] Somthing scary and unknown happened: #{ex.message}"
    nil
  end

  def process_single_html(paginated_url, block)
    @logger.info "Scraping #{paginated_url} ..."
    block[Nokogiri::HTML(open(paginated_url).read)]
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
