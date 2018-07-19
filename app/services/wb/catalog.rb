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
    PRICE = 'price'.freeze
    MIN_PRICE = 'minPrice'.freeze
    COUPON_PRICE = 'couponPrice'.freeze
    PROMO_PRICES_HEADERS = {
      'Host' => ENV['KB_HOST'],
      'Accept' => '*/*',
      'Accept-Language' => 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
      'Referer' => "https://#{ENV['KB_HOST']}/catalog/zhenshchinam/odezhda/platya?pagesize=200",
      'X-Requested-With' => 'XMLHttpRequest',
      'Cookie' => '__ver=52291; mobile_client=0; BasketUID=733053e2-6f13-33d0-a129-c397314da31d; __store=507_1699_1733_686; __catalogOptions=Sort:Popular&CountItems:200; ___wbuV1=userId=733c9a49-739a-4225-a9e3-186a4aed33af&firstVisit=06/17/2018 11:31:30&lastVisit=06/17/2018 13:43:30; ___wbs=sessionId=c233cafe-e3fd-463f-b364-fdb3336370b8&startDateTime=06/17/2018 11:34:30; ASP.NET_SessionId=0v0f3oishuag3gomega16klq',
      'DNT' => '1',
      'Connection' => 'keep-alive',
      'Pragma' => 'no-cache',
      'Cache-Control' => 'no-cache'
    }.freeze

    def initialize(*args)
      super

      @promo_prices_conn = Faraday.new(url: "#{supplier.host}/content/cardspromo") do |conn|
        conn.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        conn.headers.merge! PROMO_PRICES_HEADERS
        conn.adapter  :net_http
      end

      @processed_count = 0
    end

    def sync
      scrape_links '/catalog/zhenshchinam/odezhda/platya?pagesize=200&brand=1110' do |page|
        products_attrs = {}

        add_ids_and_titles_and_category_to! products_attrs, page
        ids = products_attrs.keys
        add_sizes_and_prices_to! products_attrs, page
        add_coupon_prices_to! products_attrs, ids

        save products_attrs

        # return links
        ids.map { |id| "/catalog/#{id}/detail.aspx" }
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

    def save(products_attrs)
      @processed_count += products_attrs.each do |remote_id, attrs|
        product = Product.find_or_initialize_by remote_id: remote_id, supplier: supplier
        update_product attrs, product
      end.size

      message = "∑  = #{@processed_count} " # + Done ✅
      @logger.info message
      puts message
    end

    def add_ids_and_titles_and_category_to!(hsh, page)
      page.css('#catalog-content>.catalog_main_table>.dtList').each do |div|
        brand_title = div.css('a .brand-name>text()').first.text.strip
        if brand_title.blank?
          @logger.error '[ADD_IDS_AND_TITLES_AND_CATEGORY_TO] No brand title is provided - skipping'
          next
        end

        title = div.css('a .goods-name').first.text.strip
        if title.blank?
          @logger.error '[ADD_IDS_AND_TITLES_AND_CATEGORY_TO] No product title is provided - skipping'
          next
        end

        branding_attributes = { brand_id: brand_from(brand_title).id }

        div.attr(ATTR).split(LINK_SPL_CHR).each do |remote_id|
          remote_id = remote_id.to_i
          hsh[remote_id] ||= {
                               title: title,
                               remote_id: remote_id,
                               branding_attributes: branding_attributes,
                               category_id: 3
                             }
        end
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

    def add_sizes_and_prices_to!(products_attrs, page)
      attrs_json = page.css(SCRIPT)
                       .find { |scr| scr.content.include? WB_SETTINGS }
                       .content[SHORT_PRODUCTS_REGEXP, 1]
      # attrs_json
        # {
        #   "2405711": {
        #     "maxPrice": 2274,
        #     "minPrice": 2274,
        #     "picsCnt": 4,
        #     "price": 3790,
        #     "sale": 40,
        #     "salePct": 36,
        #     "sizes": [
        #       {
        #         "ch": 9985529,
        #         "nm": "44"
        #       },
        #       {
        #         "ch": 9985530,
        #         "nm": "46"
        #       },
        #       {
        #         "ch": 9985531,
        #         "nm": "48"
        #       },
        #       {
        #         "ch": 9985532,
        #         "nm": "42"
        #       }
        #     ],
        #     "vid": true
        #   },
        #   ...
        # }
      #

      attrs_hash = JSON.parse(attrs_json)
                       .tap { |hsh| hsh.keys.each { |key| hsh[key.to_i] = hsh.delete(key) } }

      # adding
      attrs_hash.each do |remote_id, attrs|
        product_attrs = products_attrs[remote_id]
        next unless product_attrs

        product_attrs[:sizes] = attrs[SIZES].map { |size| size[NM] }
        product_attrs[:original_price] = attrs[PRICE]
        product_attrs[:discount_price] = attrs[MIN_PRICE]
      end
    end

    def add_coupon_prices_to!(products_attrs, ids)
      prices_json = fetch_json payload: { nmList: ids }

      # [{"sale"=>20, "bonus"=>0, "couponPrice"=>1488, "nmId"=>5218132}, ...]
      prices_arr = JSON.parse prices_json

      # adding
      prices_arr.each do |attrs|
        product_attrs = products_attrs[attrs[NMID]]
        product_attrs[:coupon_price] = attrs[COUPON_PRICE]
      end
    end

    def fetch_json(payload:)
      print "POST [JSON] to #{@promo_prices_conn.url_prefix} ..."

      response = @promo_prices_conn.post do |req|
        req.body = URI.encode_www_form(payload)
      end
      puts ' Done ✅'

      # puts " Got #{response.status.first} - treating it as the end of the journey. ✅"
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
