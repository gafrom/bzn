module Gepur
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithTrackedProductUpdates

    def sync
      update_file catalog: '/xml/gepur_catalog.csv'
      # Gepur catalog csv contains two concatenated tables:
      # - First goes Categories with headers `id, category, parentId`
      # - Then Products with headers `id_product, avaliable, ...`
      reading = nil
      CSV.foreach path_to_file(:catalog), col_sep: ';' do |row|
        if row[1] == 'category'
          puts "Reading table `categories` with columns: #{row}"
          next reading = :categories
        elsif row[0] == 'id_product'
          puts "Reading table `products` with columns: #{row}"
          next reading = :products
        end

        store row, reading
      end

      hide_removed_products

      puts "\nUpdating dresses lengths ..."
      update_dresses_lengths

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Dresses: #{@updated_dresses_count}\n" \
           "Failures: #{@failures_count}"

    end

    private

    def update_dresses_lengths
      @updated_dresses_count = 0

      dresses.each do |dress|
        @pool.run { synchronize_dress_length dress }
        # synchronize_dress_length dress
      end

      @pool.await_completion
    end

    def synchronize_dress_length(dress)
      attrs = parse_dress URI("#{supplier.host}#{dress.url}")
      update_product attrs, dress
      @updated_dresses_count += 1
    rescue OpenURI::HTTPError, Net::ReadTimeout, Net::OpenTimeout, NotImplementedError => ex
      log_failure_for dress.url, ex.message
    end

    def parse_dress(uri)
      content = open(uri, request_headers).read
      page = Nokogiri::HTML content

      dress_attributes_from page
    end

    def dress_attributes_from(page)
      attrs = {}
      length = page.css('.content .desctiption__common .d-info')
                   .find { |node| node.text =~ /длина:/i }&.next_element&.text.to_i
      return attrs if length == 0

      attrs[:length] = length
      attrs[:properties] = [Property.from_length(length)]

      attrs
    end

    def dresses
      Product.available.where supplier: supplier, category_id: 3
    end

    def store(data, type)
      case type
      # do not do anything for categories entries
      #
      # when :categories
      #   remote_id, title, remote_parent_id = data
      #   parent = Categorizer.new(remote_parent_id).category
      #   Category.where(remote_id: remote_id).first_or_create do |cat|
      #     cat.assign_attributes title: title, parent: parent
      #   end
      when :products
        attrs = product_attributes_from data
        update_product attrs
      end
    end

    def product_attributes_from(data)
      attrs = %i[remote_key is_available remote_category_id _ title url description
                 collection color sizes compare_price price images].zip(data).to_h
      attrs.delete :_

      categorizer = Categorizer.new remote_id: attrs.delete(:remote_category_id)
      attrs[:category_id]  = categorizer.category_id
      attrs[:is_available] = attrs[:is_available].downcase == 'true'
      attrs[:url]          = attrs[:url][/https?:\/\/gepur\.com(\/product\/[^\s\n\t]+)/, 1]

      attrs[:sizes] = if attrs[:sizes].present?
                        attrs[:sizes].downcase.split(', ').compact
                      else
                        ['unified']
                      end

      attrs[:price]         = attrs[:price][/RUB:(\d+)/, 1]
      attrs[:compare_price] = attrs[:compare_price][/RUB:(\d+)/, 1]
      attrs[:images]        = attrs[:images].gsub(/\/[^\/]+\/([^\/]+(,|\z))/, '/origins/\1')
                                            .gsub(/https?:\/\/gepur\.com/, '')
                                            .split(',').compact
      attrs[:color_ids] = @colorizer.ids attrs[:color] if attrs[:color].present?
      description = attrs[:description].split(/(?<=[а-я])(?=[А-Я])/).map do |desc|
        "<p>#{desc.strip}</p>"
      end.join
      attrs[:description] = description

      attrs
    end
  end
end
