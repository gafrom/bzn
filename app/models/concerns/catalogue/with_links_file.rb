# Methods to be implemented for a base class:
# - update_links
#
module Catalogue::WithLinksFile
  private

  def obsolete?
    empty? || (last_modified_at + self.class::STALE_IN).past?
  end

  def empty?
    dir = File.dirname path_to_file
    Dir.mkdir dir unless File.directory? dir

    !File.exists? path_to_file
  end

  def last_modified_at
    File.mtime path_to_file
  end

  # def path_to_links_file
  #   Rails.root.join 'storage', "#{self.class.name.underscore}.links"
  # end

  def path_to_file(key = nil)
    key_part = key ? ".#{key}" : ''
    Rails.root.join 'storage', "#{self.class.name.underscore}#{key_part}"
  end
end
