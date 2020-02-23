module Catalogue::WithLinksScraper
  PAGE_LIMIT = 300

  private

  def scrape_links(paths = nil, to: :disk, format: :html, start_page: 1, paginate: true,
                   after_loop: nil, &block)
    if to == :disk
      return unless obsolete?(:links)
      # erase contents now and append later by chunks
      CSV.open path_to_file(:links), 'wb'
    end

    paths = [paths] unless paths.respond_to? :each
    start_page = paginate ? start_page : false
    @links_count = 0
    @pages_count = 0

    paths.each do |path|
      abs_url = "#{supplier.host}#{path}"
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
                    process_single_json "#{path}#{param_prifix}page=#{num}", ref_url, block
                  end

          @pages_count += 1
          break if links.blank?

          send "put_to_#{to}", links
          @links_count += links.size if links.respond_to? :size
        end
      else
        links = case format
                when :plain then process_single_body abs_url, block
                when :html  then process_single_html abs_url, block
                when :json  then process_single_json path, supplier.host, block
                end

        @pages_count += 1
        next if links.blank?

        send "put_to_#{to}", links
        @links_count += links.size if links.respond_to? :size
      end

      after_loop.call(path) if after_loop
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

  def process_single_json(path, ref_url, block)
    @logger.info "Scraping JSON from #{path} ..."
    @requests_count += 1
    response = @general_conn.post path, nil, Referer: ref_url

    if response.success?
      json = JSON.parse(response.body).merge!(path: path)
      block[json]
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
    @requests_count += 1
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
    @requests_count += 1
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
