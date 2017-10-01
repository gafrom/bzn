require 'open-uri'
require 'csv'

module Gepur
  class Catalog
    PATH_TO_FILE = Rails.root.join('storage', 'gepur_catalog.csv')
    URI = URI('https://gepur.com/xml/gepur_catalog.csv')

    def initialize
      @failures_count = 0
      @success_count  = 0
    end

    def read
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

      puts "Successes: #{@success_count}\nFailures: #{@failures_count}"
    end

    private

    def ensure_local_copy_is_fresh
      update if empty? || (last_modified_at + 10.hours).past?
    end

    def empty?
      !File.exists? PATH_TO_FILE
    end

    def last_modified_at
      ::File.mtime PATH_TO_FILE
    end

    def update
      puts 'Updating catalog file...'
      IO.copy_stream open(URI), PATH_TO_FILE
    end

    def store(data, type)
      case type
      when :categories
        remote_id, title, remote_parent_id = data
        parent = Category.find_by! remote_id: remote_parent_id
        Category.where(remote_id: remote_id).first_or_create do |cat|
          cat.assign_attributes title: title, parent: parent
        end
      when :products
        attrs = product_attributes_from data

        product = Product.find_by remote_id: attrs[:remote_id]
        product ? product.update(attrs) : Product.create(attrs)

        @success_count += 1
      end
    rescue NoMethodError
      @failures_count += 1
    end

    def product_attributes_from(data)
      attrs = %i[remote_id is_available remote_category_id _ title url description
                 collection color sizes compare_price price images].zip(data).to_h
      attrs.delete :_
      attrs.merge! supplier: Gepur.supplier

      attrs[:category] = Category.find_by! remote_id: attrs.delete(:remote_category_id)
      attrs[:is_available]  = attrs[:is_available].downcase == 'true'
      attrs[:url]           = attrs[:url][/https?:\/\/gepur\.com\/product\/([^\s\n\t]+)/, 1]
      attrs[:sizes]         = attrs[:sizes].downcase.split(', ').compact
      attrs[:price]         = attrs[:price][/RUB:(\d+)/, 1]
      attrs[:compare_price] = attrs[:compare_price][/RUB:(\d+)/, 1]
      attrs[:images]        = attrs[:images].gsub(/\/[^\/]+\/([^\/]+(,|\z))/, '/origins/\1')
                                            .gsub(/https?:\/\/gepur\.com/, 'http://151.248.118.98')
                                            .split(',').compact

      attrs
    end
  end
end
