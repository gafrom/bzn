require 'open-uri'
require 'csv'

module Gepur
  class Catalog < ::Catalog
    include Catalogue::WithSupplier

    PATH_TO_FILE = Rails.root.join('storage', 'gepur_catalog.csv')
    URI = URI('https://gepur.com/xml/gepur_catalog.csv')

    def sync
      ensure_local_copy_is_fresh
      # Gepur catalog csv contains two concatenated tables:
      # - First goes Categories with headers `id, category, parentId`
      # - Then Products with headers `id_product, avaliable, ...`
      reading = nil
      CSV.foreach PATH_TO_FILE, col_sep: ';' do |row|
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

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def hide_removed_products
      removed_from_catalog = Product.where(supplier: Gepur.supplier, is_available: true)
                                    .where.not(id: @processed)
      removed_from_catalog.update_all is_available: false

      @hidden_count = removed_from_catalog.count
    end

    def ensure_local_copy_is_fresh
      update if empty? || (last_modified_at + STALE_IN).past?
    end

    def empty?
      !File.exists? PATH_TO_FILE
    end

    def last_modified_at
      File.mtime PATH_TO_FILE
    end

    def update
      puts 'Updating catalog file...'
      IO.copy_stream open(URI), PATH_TO_FILE
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

        product = Product.find_or_initialize_by remote_key: attrs[:remote_key]
        product.assign_attributes attrs
        was_new_record = product.new_record?
        was_changed    = product.changed?
        return @failures_count += 1 unless product.save

        @processed << product.id

        return @created_count += 1 if was_new_record
        return @updated_count += 1 if was_changed
        @skipped_count += 1
      end
    rescue NoMethodError
      @failures_count += 1
    end

    def product_attributes_from(data)
      attrs = %i[remote_key is_available remote_category_id _ title url description
                 collection color sizes compare_price price images].zip(data).to_h
      attrs.delete :_
      
      attrs.merge! supplier: Supplier.find_by!

      categorizer = Gepur::Categorizer.new attrs.delete(:remote_category_id)
      attrs[:category_id]   = categorizer.category_id
      attrs[:is_available]  = attrs[:is_available].downcase == 'true'
      attrs[:url]           = attrs[:url][/https?:\/\/gepur\.com\/product\/([^\s\n\t]+)/, 1]
      attrs[:sizes]         = attrs[:sizes].downcase.split(', ').compact
      attrs[:price]         = attrs[:price][/RUB:(\d+)/, 1]
      attrs[:compare_price] = attrs[:compare_price][/RUB:(\d+)/, 1]
      attrs[:images]        = attrs[:images].gsub(/\/[^\/]+\/([^\/]+(,|\z))/, '/origins/\1')
                                            .gsub(/https?:\/\/gepur\.com/, '')
                                            .split(',').compact

      attrs
    end
  end
end
