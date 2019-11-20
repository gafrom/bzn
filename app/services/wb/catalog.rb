module Wb
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates
    extend Catalogue::WithSupplierClassMethods

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
    OWN_PATH = ENV['KB_OWN_PATH']

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

      @processed_count = 0
      @requests_count = 0
      @created_daily_facts_count = 0
      @deleted_daily_facts_count = 0
      @created_hourly_facts_count = 0
      @deleted_hourly_facts_count = 0
      @started_at = Time.zone.now
    end

    def sync(only_new: false)
      urls = only_new ? latest_products_url : complete_urls_set

      scrape_links urls, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json, override: { category_id: 3 }
        add_coupon_prices_and_feedback_count_to! products_attrs

        save(products_attrs, only_new: only_new) || break
      end

      hide_unavailable_products unless only_new
      delete_old_facts unless only_new
    rescue StandardError => ex
      @logger.error ex
    ensure
      spit_results "sync:#{only_new ? 'latest' : 'all'}"
    end

    def sync_own
      scrape_links OWN_PATH, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff! to: products_attrs, from: json

        save products_attrs, create_hourly_facts: true
      end

      delete_old_hourly_facts
    rescue StandardError => ex
      @logger.error ex
    ensure
      spit_results 'sync:own'
    end

    def sync_orders_counts
      recent_products.find_each do |product|
        next if @processed.include? product.remote_id

        process_single_get_json product.rel_path do |json|
          # @pool.run { update_sold_counts_from json }
          update_sold_counts_from json
        end

        sleep 0.2
      end

      # @pool.await_completion
    rescue StandardError => ex
      @logger.error ex
    ensure
      spit_results 'sync:orders_counts'
    end

    private

    def process_single_get_json(path)
      @logger.info "Scraping JSON from #{path} ..."

      begin
        response = @joke_conn.get path
      rescue StandardError => ex
        retry_num ||= 0
        if retry_num < 6
          @logger.error "[PROCESS_SINGLE_GET_JSON] Connection failed ☠ . ️"\
                        "Reconnecting... (retry ##{retry_num += 1})"
          sleep 1.5**retry_num
          retry
        end

        @logger.error "[PROCESS_SINGLE_GET_JSON] Terminating after #{retry_num + 1} attempts."
        @logger.error ex
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
        next log_warning_for remote_id, 'No ordersCount' unless sold_count

        product.assign_attributes sold_count: sold_count
        was_changed = product.changes if product.changed?
        product.save
        @processed_count += 1

        save_daily_fact(product, was_changed)

        next increment_updated product, was_changed if was_changed
        skip product, touch: false
      end
    end

    def recent_products
      Product.joins('INNER JOIN daily_facts ON products.id = daily_facts.product_id')
             .where('products.supplier_id = ? '\
                    'AND daily_facts.created_at >= ? '\
                    'AND daily_facts.is_available = ?', supplier.id, 1.week.ago.to_date, true)
             .distinct
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
        category_id = if override&.key?(:category_id)
                        override[:category_id]
                      else
                        Categorizer.safe_id_from_title(title)
                      end

        unless category_id
          @logger.error "[ADD_PRIMARY_STUFF_TO] Cannot infer category "\
                        "from title: #{title}, remote_id: #{remote_id}"
          next
        end

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
          category_id: category_id,
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

    def brand_from(title)
      brand = Brand.find_or_initialize_by title: title
      if brand.new_record?
        @logger.info "[ADD_PRIMARY_STUFF_TO:BRAND_FROM] Create brand '#{title}'"
      end
      brand.save
      brand
    end

    def add_coupon_prices_and_feedback_count_to!(products_attrs)
      response_json = fetch_json_from_api_v1("nm=#{products_attrs.keys.join(?;)}")

      response = JSON.parse response_json
      prices_arr = response.dig('data', 'products')

      if prices_arr.blank?
        @logger.info "[ADD_COUPON_PRICES_AND_FEEDBACK_COUNT_TO!] [ERROR] Got empty JSON - No salePrices added. ✅"
        return
      end

      # adding
      prices_arr.each do |attrs|
        product_attrs = products_attrs[attrs[ID]]
        product_attrs[:coupon_price] = attrs[COUPON_PRICE]
        product_attrs[:feedback_count] = attrs[FEEDBACK_COUNT]
      end
    rescue JSON::ParserError => error
      @logger.info "[ADD_COUPON_PRICES_AND_FEEDBACK_COUNT_TO!] [ERROR] Got wrong JSON (#{error.message}) - No salePrices added. ✅"
      nil
    end

    def save(products_attrs, opts = {})
      all_were_new = products_attrs.each do |remote_id, attrs|
        product = Product.find_or_initialize_by remote_id: remote_id, supplier: supplier
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
        if retry_num < 6
          @logger.error "[FETCH_JSON_FROM_API_V1] Connection failed ☠ . ️"\
                        "Reconnecting... (retry ##{retry_num += 1})"
          sleep 1.5**retry_num
          retry
        end

        @logger.error "[FETCH_JSON_FROM_API_V1] Terminating after #{retry_num + 1} attempts."
        @logger.error ex
      end

      response.body if response.success?
    end

    def synchronize_prices(url, product)
      update_product attrs, product
    rescue OpenURI::HTTPError, Net::ReadTimeout, Net::OpenTimeout, NotImplementedError => ex
      log_failure_for url, ex.message
    ensure
      @processed << product.id if product
    end

    def latest_products_url
      '/catalog/zhenshchinam/odezhda/platya?pagesize=200&sort=newly'
    end

    def complete_urls_set
      %w[
        /catalog/zhenshchinam/odezhda/platya?price=0;900
        /catalog/zhenshchinam/odezhda/platya?price=901;1100
        /catalog/zhenshchinam/odezhda/platya?price=1101;1300
        /catalog/zhenshchinam/odezhda/platya?price=1301;1400
        /catalog/zhenshchinam/odezhda/platya?price=1401;1550
        /catalog/zhenshchinam/odezhda/platya?price=1551;1700
        /catalog/zhenshchinam/odezhda/platya?price=1701;1850
        /catalog/zhenshchinam/odezhda/platya?price=1851;2000
        /catalog/zhenshchinam/odezhda/platya?price=2001;2100
        /catalog/zhenshchinam/odezhda/platya?price=2101;2200
        /catalog/zhenshchinam/odezhda/platya?price=2201;2300
        /catalog/zhenshchinam/odezhda/platya?price=2301;2400
        /catalog/zhenshchinam/odezhda/platya?price=2401;2500
        /catalog/zhenshchinam/odezhda/platya?price=2501;2600
        /catalog/zhenshchinam/odezhda/platya?price=2601;2700
        /catalog/zhenshchinam/odezhda/platya?price=2701;2800
        /catalog/zhenshchinam/odezhda/platya?price=2801;2910
        /catalog/zhenshchinam/odezhda/platya?price=2911;3040
        /catalog/zhenshchinam/odezhda/platya?price=3041;3150
        /catalog/zhenshchinam/odezhda/platya?price=3151;3250
        /catalog/zhenshchinam/odezhda/platya?price=3251;3370
        /catalog/zhenshchinam/odezhda/platya?price=3371;3520
        /catalog/zhenshchinam/odezhda/platya?price=3521;3700
        /catalog/zhenshchinam/odezhda/platya?price=3701;3800
        /catalog/zhenshchinam/odezhda/platya?price=3801;3900
        /catalog/zhenshchinam/odezhda/platya?price=3901;4100
        /catalog/zhenshchinam/odezhda/platya?price=4101;4300
        /catalog/zhenshchinam/odezhda/platya?price=4301;4600
        /catalog/zhenshchinam/odezhda/platya?price=4601;5000
        /catalog/zhenshchinam/odezhda/platya?price=5001;5500
        /catalog/zhenshchinam/odezhda/platya?price=5501;6000
        /catalog/zhenshchinam/odezhda/platya?price=6001;7000
        /catalog/zhenshchinam/odezhda/platya?price=7001;8000
        /catalog/zhenshchinam/odezhda/platya?price=8001;9000
        /catalog/zhenshchinam/odezhda/platya?price=9001;98000
      ].map { |url| url << "#{url.include?('?') ? '&' : '?'}pagesize=200" }
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
      query = DailyFact.where 'created_at < ?', 2.months.ago
      @deleted_daily_facts_count = query.delete_all
    end

    def delete_old_hourly_facts
      query = HourlyFact.where 'created_at < ?', 2.months.ago
      @deleted_hourly_facts_count = query.delete_all
    end

    def log_warning_for(remote_id, msg = 'No product found')
      @logger.warn "[SYNC_ORDERS_COUNTS] #{msg} for remote_id: #{remote_id}"
      @failures_count += 1
    end

    def spit_results(tag = nil)
      message = "[RESULTS @ #{tag}] "\
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
    end
  end
end
