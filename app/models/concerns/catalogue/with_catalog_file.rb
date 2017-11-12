module Catalogue::WithCatalogFile
  private

  def catalog_contents
    if block_given?
      self.class::CATALOG_URL.keys.each do |type|
        yield File.open(path_to_file(type)).read
      end
    else
      File.open(path_to_file).read
    end
  end

  def update
    case self.class::CATALOG_URL
    when String
      update_catalog_file self.class::CATALOG_URL
    else
      self.class::CATALOG_URL.each { |key, url| update_catalog_file url, key }
    end
  end

  def update_catalog_file(url, key = nil)
    uri = URI "#{supplier.host}/#{url}"
    print "Updating #{key} catalog file from #{uri}... "
    IO.copy_stream open(uri), path_to_file(key)
    puts 'Done'
  end
end
