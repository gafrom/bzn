# Methods to be implemented for a base class:
# - update_links
#
module Catalogue::WithFile
  private

  def update_file(urls)
    @files_urls = urls
    @files_urls.each { |file_url| update_single_file *file_url }
  end

  alias update_files update_file

  def update_single_file(file_key, url)
    return unless obsolete? file_key

    uri = URI "#{supplier.host}#{url}"
    print "Updating #{file_key} catalog file from #{uri}... "
    IO.copy_stream open(uri), path_to_file(file_key)
    puts 'Done'
  end

  def obsolete?(key)
    empty?(key) || (last_modified_at(key) + self.class::STALE_IN).past?
  end

  def empty?(key)
    dir = File.dirname path_to_file(key)
    Dir.mkdir dir unless File.directory? dir

    !File.exists? path_to_file(key)
  end

  def last_modified_at(key)
    File.mtime path_to_file(key)
  end

  def path_to_file(key = nil)
    key_part = key ? ".#{key}" : ''
    Rails.root.join 'storage', "#{self.class.name.underscore}#{key_part}"
  end

  def file_contents(type = nil)
    if block_given?
      self.class::FILE_URL.keys.each do |type|
        yield File.open(path_to_file(type)).read
      end
    else
      # type = self.class::FILE_URL.keys.first
      raise AttributeError unless type
      File.open(path_to_file(type)).read
    end
  end
end
