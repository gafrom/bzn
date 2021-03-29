module Wb
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates
    extend Catalogue::WithSupplierClassMethods
    extend Catalogue::WithErrorsCaught

    LINK_SPL_CHR = ','.freeze
    ID = 'id'.freeze
    ATTR = 'data-colors'.freeze
    SIZES = 'sizes'.freeze
    NM = 'nm'.freeze
    SCRIPT = 'script'.freeze
    WB_SETTINGS = 'wb.settings'.freeze
    SHORT_PRODUCTS_REGEXP = /shortProducts\:\s(.*)\s\}\)\;/
    EXTRACT_PRODUCT_INIT_DATA = /wb\.product\.DomReady\.init\((.*?)\);/m
    NAME = 'name'.freeze
    BRAND = 'brand'.freeze
    MARK = 'mark'.freeze
    COLOR = 'color'.freeze
    COLORS = 'colors'.freeze
    PRICE = 'price'.freeze
    NOMENCL = 'nomenclatures'.freeze
    OC = 'ordersCount'.freeze
    MIN_PRICE = 'minPrice'.freeze
    COD1S = 'cod1S'.freeze
    COUPON_PRICE = 'salePrice'.freeze
    FEEDBACK_COUNT = 'feedbackCount'.freeze
    RATING = 'rating'.freeze
    PROMO_PRICES_HEADERS = {
      'Accept' => '*/*',
      'Accept-Language' => 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
      'X-Requested-With' => 'XMLHttpRequest',
      'DNT' => '1',
      'Connection' => 'keep-alive',
      'Pragma' => 'no-cache',
      'Cache-Control' => 'no-cache'
    }.freeze
    INDEX_PAGE_HEADERS = {
      'User-Agent' => ENV['KB_USER_AGENT'],
      'Accept' => 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language' => 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
      'X-Requested-With' => 'XMLHttpRequest',
      'DNT' => '1',
      'Content-Type' => 'application/json; charset=UTF-8',
      'Connection' => 'keep-alive',
      'Pragma' => 'no-cache',
      'Cache-Control' => 'no-cache'
    }.freeze
    API_V1_URL = ENV['API_V1_URL']
    BATCH_SIZE = 200

    catch_errors_for :sync_once, :sync_latest, :sync_daily, :sync_hourly, :sync_orders_counts,
                     :sync_products, :fetch_product_remote_ids

    def initialize(*)
      super

      @promo_prices_conn = Faraday.new(url: API_V1_URL) do |conn|
        conn.headers.merge! PROMO_PRICES_HEADERS
        conn.adapter :net_http
      end

      @general_conn = Faraday.new(url: supplier.host) do |conn|
        conn.headers.merge! INDEX_PAGE_HEADERS
        conn.adapter :net_http
      end

      @joke_conn = Faraday.new(url: ENV['KB_JOKE_BASE_URL']) do |conn|
        conn.adapter :net_http
      end

      @spit_results_was_invoked = false
      @processed_count = 0
      @requests_count = 0
      @created_daily_facts_count = 0
      @deleted_daily_facts_count = 0
      @created_hourly_facts_count = 0
      @deleted_hourly_facts_count = 0
      @started_at = Time.zone.now

      @brands_cache = {}
    end

    def sync_latest(urls)
      scrape_links urls, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json
        add_coupon_prices_and_feedback_count_to! products_attrs

        save(products_attrs, only_new: true) || break
      end
    end

    def sync_once(urls, callback = nil)
      scrape_links urls, to: :nowhere, format: :json, after_loop: callback do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json
        add_coupon_prices_and_feedback_count_to! products_attrs

        save products_attrs
      end
    end

    def sync_daily(urls, after_url_done_callback: nil, after_request_processed_callback: nil)
      scrape_links urls, to: :nowhere, format: :json, after_pagination_end: after_url_done_callback do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json, override: { category_id: 3 }
        add_coupon_prices_and_feedback_count_to! products_attrs

        save products_attrs

        products_processed = Product.where(remote_id: products_attrs.keys, supplier: supplier)
        after_request_processed_callback.call(products_processed) if after_request_processed_callback
      end

      # hide_unavailable_products
      delete_old_facts
    end

    def fetch_product_remote_ids(urls, after_url_done_callback: nil, &block)
      scrape_links(urls, to: :nowhere,
                         format: :json,
                         after_pagination_end: after_url_done_callback) do |json|
        block.call(extract_remote_ids(json))
      end
    end

    def sync_products(remote_ids, after_batch_callback: nil)
      remote_ids.each_slice(BATCH_SIZE) do |few_remote_ids|
        products_attrs = batch_fetch_from_api_v1(few_remote_ids)

        save products_attrs
        after_batch_callback.call(products_attrs.keys) if after_batch_callback
      end

      delete_old_facts
    end

    def sync_hourly(urls)
      scrape_links urls, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json

        save products_attrs, create_hourly_facts: true
      end

      delete_old_hourly_facts
    end

    def sync_orders_counts(products)
      products.find_each do |product|
        next if @processed.include? product.remote_id

        process_single_get_json product.rel_path do |json|
          update_sold_counts_from json
        end

        sleep 0.2
      end
    end

    private

    def process_single_get_json(path)
      @logger.info "Scraping JSON from #{path} ..."

      begin
        response = @joke_conn.get path
      rescue StandardError => ex
        retry_num ||= 0
        if retry_num < 10
          @logger.warn "[PROCESS_SINGLE_GET_JSON] Connection failed ☠ . ️"\
                        "Reconnecting... (retry ##{retry_num += 1})"
          sleep 1.9**retry_num
          retry
        end

        @logger.error "[PROCESS_SINGLE_GET_JSON] Terminating after #{retry_num + 1} attempts."
        raise ex
      end

      @requests_count += 1

      if response.success?
        yield JSON.parse(response.body)
      else
        @logger.info "Got #{response.status} - treating it as the end of the journey. ✅"
      end
    rescue JSON::ParserError => error
      @logger.info "Got wrong JSON (#{error.message}) - treating it as the end of the journey. ✅"
    end

    def update_sold_counts_from(json)
      products_attrs = json['data']['colors']
      update_sold_counts_for products_attrs if products_attrs.present?
    end

    def update_sold_counts_for(products_attrs)
      products_attrs.each do |product_attrs|
        remote_id = product_attrs[COD1S].to_i
        @processed << remote_id if remote_id > 0

        product = Product.find_by remote_id: remote_id
        next log_warning_for remote_id unless product

        sold_count = product_attrs[NOMENCL][0][OC].to_i
        next log_warning_for remote_id, "No #{OC}" unless sold_count

        product.assign_attributes sold_count: sold_count
        was_changed = product.changes if product.changed?
        product.save
        @processed_count += 1

        save_daily_fact(product, was_changed)

        next increment_updated product, was_changed if was_changed
        skip product, touch: false
      end
    end

    def extract_remote_ids(from)
      from['products'].map { |attrs| attrs[COD1S].to_i }
    end

    def add_primary_stuff!(to:, from:, override: nil)
      from['products'].each do |attrs|
        remote_id = attrs[COD1S].to_i
        title = attrs[NAME]
        brand_title = attrs[BRAND]

        if title.blank? || brand_title.blank?
          missing = case
                    when title.blank? then 'product title'
                    when brand_title.blank? then 'brand title'
                    end
          @logger.error "[ADD_PRIMARY_STUFF_TO] No #{missing} is provided - skipping"
          next
        end

        branding_attributes = { brand_id: brand_from(brand_title).id }

        to[remote_id] ||= {
          title: title,
          remote_id: remote_id,
          original_price: attrs[PRICE],
          discount_price: attrs[MIN_PRICE],
          rating: attrs[MARK],
          color: attrs[COLOR],
          branding_attributes: branding_attributes,
          url: "/catalog/#{remote_id}/detail.aspx",
          remote_key: remote_id,
          new_supplier_category: supplier_category_from(from[:path]),
          is_available: true
        }
      end

      # converting str keys to integers and then adding sizes
      from['shortProducts'].tap { |h| h.keys.each { |key| h[key.to_i] = h.delete(key) } }
                           .each do |remote_id, attrs|
        product_attrs = to[remote_id]
        next unless product_attrs

        product_attrs[:sizes] = attrs[SIZES].map { |size| size[NM] }
      end
    end

    def supplier_category_from(path)
      query_string_index = path.index ??
      path = query_string_index ? path.slice(0, query_string_index) : path
      SupplierCategory.find_or_create_by name: path, supplier: supplier
    end

    def brand_from(title)
      @brands_cache[title] ||= begin
        brand = Brand.find_or_initialize_by title: title
        if brand.new_record?
          @logger.info "[ADD_PRIMARY_STUFF_TO:BRAND_FROM] Create brand '#{title}'"
        end
        brand.save
        brand
      end
    end

    def add_coupon_prices_and_feedback_count_to!(products_attrs)
      response_json = fetch_json_from_api_v1("nm=#{products_attrs.keys.join(?;)}")

      response = JSON.parse response_json
      prices_arr = response.dig('data', 'products')

      if prices_arr.blank?
        @logger.warn "[ADD_COUPON_PRICES_AND_FEEDBACK_COUNT_TO!] Got empty JSON - No salePrices added. ✅"
        return
      end

      # adding
      prices_arr.each do |attrs|
        product_attrs = products_attrs[attrs[ID]]
        product_attrs[:coupon_price] = attrs[COUPON_PRICE]
        product_attrs[:feedback_count] = attrs[FEEDBACK_COUNT]
      end
    rescue JSON::ParserError => error
      @logger.error "[ADD_COUPON_PRICES_AND_FEEDBACK_COUNT_TO!] Got wrong JSON (#{error.message}) - No salePrices added. ✅"
      nil
    end

    def batch_fetch_from_api_v1(product_remote_ids)
      response_json = fetch_json_from_api_v1("nm=#{product_remote_ids.join(?;)}")
      return {} if response_json.blank?

      response = JSON.parse response_json
      raw_products = response.dig('data', 'products')

      if raw_products.blank?
        @logger.warn "[BATCH_FETCH_FROM_API_V1] Got empty JSON for ids #{product_remote_ids}"
        return {}
      end

      products_attrs = {}

      raw_products.each do |attrs|
        remote_id = attrs[ID].to_i
        brand_title = attrs[BRAND]
        sizes = attrs[SIZES]

        missing = case
                  when remote_id == 0 then 'remote_id'
                  when brand_title.nil? || brand_title.empty? then 'brand'
                  end

        if missing
          @logger.error "[BATCH_FETCH_FROM_API_V1] No #{missing} is provided - skipping"
          next
        end

        products_attrs[remote_id] = {
          title: attrs[NAME],
          remote_id: remote_id,
          sizes: sizes.map { |size| size[NAME] },
          original_price: attrs[PRICE],
          rating: attrs[RATING],
          color: attrs[COLORS].first&.[](NAME),
          branding_attributes: { brand_id: brand_from(brand_title).id },
          url: "/catalog/#{remote_id}/detail.aspx",
          remote_key: remote_id,
          is_available: !(sizes.nil? || sizes.empty?),
          coupon_price: attrs[COUPON_PRICE],
          feedback_count: attrs[FEEDBACK_COUNT]
        }
      end

      products_attrs
    rescue JSON::ParserError => error
      @logger.error "[BATCH_FETCH_FROM_API_V1] Got wrong JSON (#{error.message})."
      nil
    end

    def save(products_attrs, opts = {})
      all_were_new = products_attrs.each do |remote_id_or_product, attrs|
        product = case remote_id_or_product
                  when Product then remote_id_or_product
                  else Product.find_or_initialize_by remote_id: remote_id_or_product,
                                                     supplier: supplier
                  end
        break false if opts[:only_new] && product.persisted?

        update_product attrs, product
        create_hourly_fact(product) if opts[:create_hourly_facts]

        @processed_count += 1
      end

      message = "∑ = #{@processed_count} ✅"
      @logger.info message

      all_were_new
    end

    def fetch_json_from_api_v1(query)
      @logger.info "GET [JSON] to #{@promo_prices_conn.url_prefix} ..."

      begin
        response = @promo_prices_conn.get do |req|
          req.params.merge_query query
        end
      rescue Exception => ex
        retry_num ||= 0
        if retry_num < 10
          @logger.warn "[FETCH_JSON_FROM_API_V1] Connection failed ☠ . ️"\
                        "Reconnecting... (retry ##{retry_num += 1})"
          sleep 1.9**retry_num
          retry
        end

        @logger.error "[FETCH_JSON_FROM_API_V1] Terminating after #{retry_num + 1} attempts."
        raise ex
      end

      return response.body if response.success?
      @logger.error "[FETCH_JSON_FROM_API_V1] Request failed with status '#{response.status}'"

      nil
    end

    def synchronize_prices(url, product)
      update_product attrs, product
    rescue OpenURI::HTTPError, Net::ReadTimeout, Net::OpenTimeout, NotImplementedError => ex
      log_failure_for url, ex.message
    ensure
      @processed << product.id if product
    end

    def hide_unavailable_products
      all_of_supplier = Product.available.where supplier: supplier
      to_be_hidden    = all_of_supplier.where 'updated_at < ?', @started_at

      share = to_be_hidden.size.fdiv all_of_supplier.size

      if share > 0.2
        @logger.error "😱  Attempt to hide more than 20% of all available products "\
                      "(requested #{to_be_hidden.size} records, #{(share * 100).round}%). "\
                      "Declined."
      else
        @hidden_count += to_be_hidden.update_all is_available: false
      end
    end

    def delete_old_facts
      query = DailyFact.where 'created_at < ?', 1.months.ago
      @deleted_daily_facts_count = query.delete_all
    end

    def delete_old_hourly_facts
      query = HourlyFact.where 'created_at < ?', 1.months.ago
      @deleted_hourly_facts_count = query.delete_all
    end

    def log_warning_for(remote_id, msg = 'No product found')
      @logger.warn "[SYNC_ORDERS_COUNTS] #{msg} for remote_id: #{remote_id}"
      @failures_count += 1
    end

    def spit_results(tag = nil, only_once: false)
      return if only_once && @spit_results_was_invoked

      message = "[RESULTS@#{tag}] "\
                "Total: #{@processed_count}, "\
                "Created: #{@created_count}, "\
                "Updated: #{@updated_count}, "\
                "Skipped: #{@skipped_count}, "\
                "Hidden: #{@hidden_count}, "\
                "Daily facts: #{@created_daily_facts_count}/#{@deleted_daily_facts_count}, "\
                "Hourly facts: #{@created_hourly_facts_count}/#{@deleted_hourly_facts_count}, "\
                "Requests: #{@requests_count}, "\
                "Failures: #{@failures_count}"
      @logger.info message

      @spit_results_was_invoked = true
    end
  end
end
