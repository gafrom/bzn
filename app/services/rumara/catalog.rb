module Rumara
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates

    NUM_THREADS = 8
    PARSING_LIMIT = 7000 # pages

    def sync
      scrape_links '/women?limit=500', start_page: 1 do |page|
        page.css('#content>.product-grid .product-grid-block>.image>a')
            .map { |a_node| a_node.attr('href').split(supplier.host).last }
      end

      process_links
      update_properties_by_title
    end

    private

    def product_attributes_from(page)
      attrs = {}
      info = page.css('#content>.product-info').first

      info_r = info.css('>.right').first

      raw_title = info_r.css('h1[itemprop="name"]').first.text.strip
      unless /\A(?<title_a>.+)\s\((?<color_a>.+)\)\s(?<brand_a>.+)\Z/ =~ raw_title
        return cannot_parse_title attrs, raw_title
      end

      attrs[:title] = title_a
      attrs[:color] = color_a
      attrs[:color_ids] = @colorizer.ids color_a
      brand_a = 'Art Style Leggings' if brand_a == 'ArtStyleLeggings'
      brand_a = 'Glem' if brand_a == 'Глем'
      brand = Brand.where('lower(title) LIKE ?', brand_a.downcase.tr(' -','_')).first
      return cannot_find_brand(attrs, brand_a) unless brand
      attrs[:branding_attributes] = { brand_id: brand.id }

      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title
      return unpermitted_category attrs if attrs[:category_id] == 15

      attrs[:price] = info_r.css('span[itemprop="price"]').first.text.to_i
      attrs[:sizes] = info_r.css('select.size-sel>option')
                            .reject { |option| option.attr('value').blank? || option.attr('data-nal') == '0' }
                            .map { |option| option.text.strip }
                            .map { |str| str == 'б/р' ? 'unified' : str }

      attrs[:description] = info_r.css('.desription>p').map { |p| p.text.strip }.join ' '

      info_l = info.css('>.left').first

      attrs[:images] =
        info_l.css('a.fancybox')
                 .map do |link|
                    href = link.attr('href')
                    next if href =~ /no_photo/

                    href.split(supplier.host).second.split('?').first
                  end.compact

      attrs[:is_available] =
        attrs[:price] > 0 && attrs[:sizes].any? && attrs[:images].any? && brand.present?
      attrs[:compare_price] = attrs[:price] * 2

      attrs
    end

    def cannot_parse_title(attrs, raw_title)
      log_failure_for raw_title, "[RUMARA] Cannot parse title '#{raw_title}'"
      {}
    end

    def cannot_find_brand(attrs, brand_title)
      log_failure_for attrs[:title], "[RUMARA] Cannot find brand '#{brand_title}'"
      {}
    end

    def unpermitted_category(attrs)
      log_failure_for attrs[:title], "[UNPERMITTED CATEGORY] Category Accessories (id=15)"
      {}
    end

    def process_links
      CSV.foreach(path_to_file(:links)).drop(offset).take(limit).each do |link|
        url = link.first
        product = Product.find_or_initialize_by remote_key: url, supplier: supplier

        @pool.run { synchronize url, product }
        # synchronize url, product
      end

      @pool.await_completion

      if final_execution?
        processed_earlier = JSON.parse File.read path_to_file(:processed)
        File.delete path_to_file(:processed)
        @processed += processed_earlier

        hide_removed_products
      else
        processed_as_json = JSON[@processed.tap { |s| s.delete(nil) if s.include?(nil) }.to_a]
        File.open(path_to_file(:processed), 'w') { |file| file.write processed_as_json }
      end

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    def final_execution?
      File.exists? path_to_file(:processed)
    end

    def offset
      final_execution? ? PARSING_LIMIT : 0
    end

    def limit
      final_execution? ? 0xffff : PARSING_LIMIT
    end
  end
end
