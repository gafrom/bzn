module Wb
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates
    extend Catalogue::WithSupplierClassMethods

    LINK_SPL_CHR = ','.freeze
    NMID = 'nmId'.freeze
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
    ORIGINAL_URL = 'originalUrl'.freeze
    COUPON_PRICE = 'couponPrice'.freeze
    PROMO_PRICES_HEADERS = {
      'Host' => ENV['KB_HOST'],
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

    def initialize(*)
      super

      @promo_prices_conn = Faraday.new(url: "#{supplier.host}/content/cardspromo") do |conn|
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
      @processed_remote_ids = Set.new
      @encountered_more_than_once = 0
      @requests_count = 0
      @deleted_facts_count = 0
      @started_at = Time.zone.now
    end

    def sync(only_new: false)
      urls = only_new ? latest_products_url : complete_urls_set

      scrape_links urls, to: :nowhere, format: :json, paginate: true do |json|
        @logger.info "[SYNC] Found #{json['products'].size} products at #{json[ORIGINAL_URL]}"
        products_attrs = {}

        add_primary_stuff_to! products_attrs, json
        add_coupon_prices_to! products_attrs

        save(products_attrs, only_new) || break

        sleep 0.2
        json['products'] # pass a collection further
      end

      # hide_unavailable_products unless only_new
      # delete_old_facts unless only_new
    rescue => ex
      @logger.error "[SYNC] Fatal error: #{ex}"
      @logger.error ex.backtrace.join("\n")
      raise ex
    ensure
      spit_results "sync:#{only_new ? 'latest' : 'all'}"
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
    rescue => ex
      @logger.error "[SYNC_ORDERS_COUNTS] Fatal error: #{ex}"
      @logger.error ex.backtrace.join("\n")
      raise ex
    ensure
      spit_results 'sync:orders_counts'
    end

    private

    def process_single_get_json(path)
      @logger.info "Scraping JSON from #{path} ..."

      begin
        response = @joke_conn.get path
      rescue Exception => ex
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

    def add_primary_stuff_to!(hsh, json)
      json['products'].each do |attrs|
        remote_id = attrs[COD1S].to_i
        next encounter_more_than_once if @processed_remote_ids.include? remote_id

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

        hsh[remote_id]  ||= {
                              title: title,
                              remote_id: remote_id,
                              original_price: attrs[PRICE],
                              discount_price: attrs[MIN_PRICE],
                              rating: attrs[MARK],
                              color: attrs[COLOR],
                              branding_attributes: branding_attributes,
                              url: "/catalog/#{remote_id}/detail.aspx",
                              remote_key: remote_id,
                              category_path: category_path_from(json),
                              category_id: 1,
                              is_available: true
                            }

        @processed_remote_ids << remote_id
      end

      # converting str keys to integers and then adding sizes
      json['shortProducts'].tap { |h| h.keys.each { |key| h[key.to_i] = h.delete(key) } }
                           .each do |remote_id, attrs|
        product_attrs = hsh[remote_id]
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

    def category_path_from(json)
      i = json[ORIGINAL_URL].index(??)
      i ? json[ORIGINAL_URL][0...i] : json[ORIGINAL_URL]
    end

    def add_coupon_prices_to!(products_attrs)
      return if products_attrs.blank?
      prices_json = fetch_json payload: { nmList: products_attrs.keys }

      # [{"sale"=>20, "bonus"=>0, "couponPrice"=>1488, "nmId"=>5218132}, ...]
      prices_arr = JSON.parse prices_json

      # adding
      prices_arr.each do |attrs|
        product_attrs = products_attrs[attrs[NMID]]
        product_attrs[:coupon_price] = attrs[COUPON_PRICE]
      end
    end

    def save(products_attrs, only_new = false)
      all_were_new = products_attrs.each do |remote_id, attrs|
        product = Product.find_or_initialize_by remote_id: remote_id, supplier: supplier
        break false if only_new && product.persisted?

        update_product attrs, product
        @processed_count += 1
      end

      message = "∑ = #{@processed_count} ✅"
      @logger.info message

      all_were_new
    end

    def fetch_json(payload:)
      @logger.info "POST [JSON] to #{@promo_prices_conn.url_prefix} ..."

      begin
        response = @promo_prices_conn.post do |req|
          req.body = URI.encode_www_form(payload)
        end
      rescue Exception => ex
        retry_num ||= 0
        if retry_num < 6
          @logger.error "[FETCH_JSON] Connection failed ☠ . ️"\
                        "Reconnecting... (retry ##{retry_num += 1})"
          sleep 1.5**retry_num
          retry
        end

        @logger.error "[FETCH_JSON] Terminating after #{retry_num + 1} attempts."
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
      raise '[ERROR] Latest products updates is not implemented.'
    end

    def complete_urls_set
      @complete_urls_set ||= begin
        l = 0
        query_params = [501, 803, 1107, 1454, 1789, 2540, 3956, 5482, 7004, 9380, 13216, 170337]
                         .map { |r| res = "?price=#{l};#{r}"; l = r + 1; res }

        File.open(Rails.root.join('storage', 'links'))
            .map { |line| line.strip }
            .product(query_params).map(&:join)
            .map { |url| url << "#{url.include?(??) ? ?& : ??}pagesize=200" }
      end
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
      @deleted_facts_count = query.delete_all
    end

    def log_warning_for(remote_id, msg = 'No product found')
      @logger.warn "[SYNC_ORDERS_COUNTS] #{msg} for remote_id: #{remote_id}"
      @failures_count += 1
    end

    def encounter_more_than_once
      @encountered_more_than_once += 1
    end

    def spit_results(tag = nil)
      message = "[RESULTS @ #{tag}] "\
                "Total processed: #{@processed_count}, "\
                "Created: #{@created_count}, "\
                "Updated: #{@updated_count}, "\
                "Skipped: #{@skipped_count}, "\
                "Encountered more than once: #{@encountered_more_than_once}, "\
                "Hidden: #{@hidden_count}, "\
                "Facts deleted: #{@deleted_facts_count}, "\
                "Requests: #{@requests_count}, "\
                "Failures: #{@failures_count}"
      @logger.info message
    end
  end
end
