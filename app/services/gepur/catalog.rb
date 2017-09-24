require 'open-uri'
require 'csv'

module Gepur
  class Catalog
    PATH_TO_FILE = Rails.root.join('storage', 'gepur_catalog.csv')
    URI = URI('https://gepur.com/xml/gepur_catalog.csv')

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
          puts cat.attributes
        end
      when :products
        byebug
      end
    end
  end
end
