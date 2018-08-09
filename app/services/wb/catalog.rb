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
    MIN_PRICE = 'minPrice'.freeze
    COD1S = 'cod1S'.freeze
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

      @processed_count = 0
      @requests_count = 0
      @started_at = Time.zone.now
    end

    def sync(only_new: false)
      urls = only_new ? latest_products_url : complete_urls_set

      scrape_links urls, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff_to! products_attrs, json
        add_coupon_prices_to! products_attrs

        save(products_attrs, only_new) || break
      end

      hide_unavailable_products unless only_new
    ensure
      spit_results "sync:#{only_new ? 'latest' : 'all'}"
    end

    def sync_orders_counts
      recent_products.find_each do |product|
        next if @processed.include? product.remote_id

        scrape_links product.url, to: :nowhere, paginate: false, format: :plain do |raw_js|
          # @pool.run { update_sold_counts_from raw_js }
          update_sold_counts_from raw_js
        end
      end

      # @pool.await_completion
    ensure
      spit_results 'sync:orders_counts'
    end

    private

    def update_sold_counts_from(raw_js)
      products_attrs = extract_products_data_from(raw_js)
      update_sold_counts_for products_attrs if products_attrs
    end

    def extract_products_data_from(raw_js)
      raw_data = raw_js[EXTRACT_PRODUCT_INIT_DATA, 1]
      ExecJS.eval(raw_data)['data']['nomenclatures']
    rescue ExecJS::Error => ex
      @logger.error "[SYNC_ORDERS_COUNTS] Failed to parse JS: #{ex.message}"
      nil
    end

    def update_sold_counts_for(products_attrs)
      products_attrs.each do |remote_id, product_attrs|
        remote_id = remote_id.to_i
        @processed << remote_id if remote_id > 0

        product = Product.find_by remote_id: remote_id
        next log_warning_for remote_id unless product

        product.assign_attributes sold_count: product_attrs['ordersCount'].to_i
        was_changed = product.changes if product.changed?
        product.save
        @processed_count += 1

        next increment_updated product, was_changed if was_changed
        skip product, touch: false
      end
    end

    def recent_products
      Product.where(supplier: supplier).where('updated_at > ?', 2.weeks.ago)
    end

    def add_primary_stuff_to!(hsh, json)
      json['products'].each do |attrs|
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
                              category_id: 3,
                              is_available: true
                            }
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

    def add_coupon_prices_to!(products_attrs)
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

      response = @promo_prices_conn.post do |req|
        req.body = URI.encode_www_form(payload)
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
        # /catalog/zhenshchinam/odezhda/platya-maksi
        # /catalog/zhenshchinam/odezhda/platya-midi?sort=priceup
        # /catalog/zhenshchinam/odezhda/platya-midi?sort=pricedown
        # /catalog/zhenshchinam/odezhda/platya-mini
        # /catalog/zhenshchinam/odezhda/svadebnye-platya
        # /catalog/zhenshchinam/odezhda/dzhnsovye-platya
        # /catalog/zhenshchinam/odezhda/sarafany
        # /catalog/zhenshchinam/odezhda/platya-s-tonkimi-bretelkami

      %w[
        /catalog/zhenshchinam/odezhda/platya?price=0;900
        /catalog/zhenshchinam/odezhda/platya?price=901;1100
        /catalog/zhenshchinam/odezhda/platya?price=1101;1300
        /catalog/zhenshchinam/odezhda/platya?price=1301;1400
        /catalog/zhenshchinam/odezhda/platya?price=1401;1550
        /catalog/zhenshchinam/odezhda/platya?price=1551;1700
        /catalog/zhenshchinam/odezhda/platya?price=1701;1850
        /catalog/zhenshchinam/odezhda/platya?price=1851;2000
        /catalog/zhenshchinam/odezhda/platya?price=2001;2200
        /catalog/zhenshchinam/odezhda/platya?price=2201;2400
        /catalog/zhenshchinam/odezhda/platya?price=2401;2600
        /catalog/zhenshchinam/odezhda/platya?price=2601;2800
        /catalog/zhenshchinam/odezhda/platya?price=2801;3040
        /catalog/zhenshchinam/odezhda/platya?price=3041;3350
        /catalog/zhenshchinam/odezhda/platya?price=3351;3600
        /catalog/zhenshchinam/odezhda/platya?price=3351;3700
        /catalog/zhenshchinam/odezhda/platya?price=3701;4300
        /catalog/zhenshchinam/odezhda/platya?price=4301;5000
        /catalog/zhenshchinam/odezhda/platya?price=5001;7000
        /catalog/zhenshchinam/odezhda/platya?price=7001;98000
      ].map { |url| url << "#{url.include?('?') ? '&' : '?'}pagesize=200" }
    end

    def hide_unavailable_products
      all_of_supplier = Product.available.where supplier: supplier
      to_be_hidden    = all_of_supplier.where 'updated_at < ?', @started_at

      share = to_be_hidden.size.fdiv all_of_supplier.size

      if share > 0.1
        @logger.error "😱  Attempt to hide more than 10% of all available products "\
                      "(requested #{to_be_hidden.size} records, #{(share * 100).round}%). "\
                      "Declined."
      else
        @hidden_count += to_be_hidden.update_all is_available: false
      end
    end

    def log_warning_for(remote_id)
      @logger.warn "[SYNC_ORDERS_COUNTS] No product found for remote_id: #{remote_id}"
      @failures_count += 1
    end

    def spit_results(tag = nil)
      message = "[RESULTS @ #{tag}] "\
                "Total processed: #{@processed_count}, "\
                "Created: #{@created_count}, "\
                "Updated: #{@updated_count}, "\
                "Skipped: #{@skipped_count}, "\
                "Hidden: #{@hidden_count}, "\
                "Requests: #{@requests_count}, "\
                "Failures: #{@failures_count}"
      @logger.info message
    end
  end
end
