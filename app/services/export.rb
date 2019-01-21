module Export
  CATEGORIES_DEPTH = 5
  PATH_TO_FILE = Rails.root.join('storage', 'export')
  BLACKLISTED = [25002, 25003, 25004, 25006, 25007].freeze

  class << self
    def obsolete?(filename)
      no_file?(filename) || latest_updated_product.updated_at > file_modified_at(filename)
    end

    def obsolescence_message_for(filename)
      return "No file found" if no_file?(filename)

      diff = latest_updated_product.updated_at - file_modified_at(filename)

      "It is stale for \e[1m#{diff.duration}\e[0m.\n"\
      "File modified_at: \e[1m#{file_modified_at(filename)}\e[0m.\n"\
      "Latest product: #{latest_updated_product.inspect}."
    end

    def path_to_file(filename)
      PATH_TO_FILE.join filename
    end

    def no_file?(filename)
      dir = File.dirname path_to_file(filename)
      Dir.mkdir dir unless File.directory? dir

      !File.exists? path_to_file(filename)
    end

    private

    def latest_updated_product
      Product.where(supplier_id: 12).order(updated_at: :desc).first
    end

    def file_modified_at(filename)
      File.mtime path_to_file(filename)
    end
  end
end
