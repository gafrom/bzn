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
      'Cookie' => ENV['KB_COOKIE'],
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
      'Cookie' => ENV['KB_COOKIE'],
      'DNT' => '1',
      'Content-Type' => 'application/json; charset=UTF-8',
      'Connection' => 'keep-alive',
      'Pragma' => 'no-cache',
      'Cache-Control' => 'no-cache'
    }.freeze

    def initialize(*args)
      super

      @promo_prices_conn = Faraday.new(url: "#{supplier.host}/content/cardspromo") do |conn|
        conn.headers.merge! PROMO_PRICES_HEADERS
        conn.adapter :net_http
      end

      @processed_count = 0
      @started_at = Time.zone.now
    end

    def sync
      scrape_links complete_urls_set, to: :nowhere, format: :json do |json|
        products_attrs = {}

        add_primary_stuff_to! products_attrs, json
        add_coupon_prices_to! products_attrs

        save products_attrs
      end
    ensure
      spit_results
    end

    def sync_links_from(urls, till_first_existing:)
      scrape_links send(urls), to: :nowhere do |page|
        page.css('#catalog-content>.catalog_main_table>.dtList').to_a.each do |div|
          datum = RemoteDatum.find_or_initialize_by remote_id: div.attr('data-catalogercod1s').to_i

          if datum.new_record?
            datum.save
            @created_count += 1
          else
            !till_first_existing || break
            @skipped_count += 1
          end

          @processed_count += 1
        end
      end
    ensure
      spit_results
    end

    private

    def latest_products_url
      '/catalog/zhenshchinam/odezhda/platya?pagesize=200&sort=newly'
    end

    def complete_urls_set
      %w[
        /catalog/zhenshchinam/odezhda/platya-maksi
        /catalog/zhenshchinam/odezhda/platya-midi?sort=priceup
        /catalog/zhenshchinam/odezhda/platya-midi?sort=pricedown
        /catalog/zhenshchinam/odezhda/platya-mini
        /catalog/zhenshchinam/odezhda/svadebnye-platya
        /catalog/zhenshchinam/odezhda/dzhnsovye-platya
        /catalog/zhenshchinam/odezhda/sarafany
        /catalog/zhenshchinam/odezhda/platya-s-tonkimi-bretelkami
      ].map { |url| url << "#{url.include?('?') ? '&' : '?'}pagesize=200" }
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
          @logger.error "[ADD_IDS_AND_TITLES_AND_CATEGORY_TO] No #{missing} is provided - skipping"
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
                              category_id: 3
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
        @logger.info "[ADD_IDS_AND_TITLES_AND_CATEGORY_TO] Create brand '#{title}'"
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

    def save(products_attrs)
      @processed_count += products_attrs.each do |remote_id, attrs|
        product = Product.find_or_initialize_by remote_id: remote_id, supplier: supplier
        update_product attrs, product
      end.size

      message = "∑  = #{@processed_count} " # + Done ✅
      @logger.info message
      puts message
    end

    def fetch_json(payload:)
      print "POST [JSON] to #{@promo_prices_conn.url_prefix} ..."

      response = @promo_prices_conn.post do |req|
        req.body = URI.encode_www_form(payload)
      end
      puts ' Done ✅'

      response.body if response.success?
    end

    def synchronize_prices(url, product)
      update_product attrs, product
    rescue OpenURI::HTTPError, Net::ReadTimeout, Net::OpenTimeout, NotImplementedError => ex
      log_failure_for url, ex.message
    ensure
      @processed << product.id if product
    end

    def spit_results
      message = "\n[RESULTS @ #{Time.zone.now}]\n" \
                "Total processed: #{@processed_count}\n" \
                "Created: #{@created_count}\n" \
                "Updated: #{@updated_count}\n" \
                "Skipped: #{@skipped_count}\n" \
                "Hidden: #{@hidden_count}\n" \
                "Failures: #{@failures_count}"
      @logger.info message
      puts message
    end
  end
end
