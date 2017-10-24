# Methods to be implemented for a base class:
# - update_links
#
module Catalogue::WithLinksFile
  private

  def ensure_links_are_fresh
    update_links if empty? || (last_modified_at + self.class::STALE_IN).past?
  end

  def empty?
    dir = File.dirname path_to_links_file
    Dir.mkdir dir unless File.directory? dir

    !File.exists? path_to_links_file
  end

  def last_modified_at
    File.mtime path_to_links_file
  end

  def path_to_links_file
    Rails.root.join 'storage', "#{self.class.name.underscore}.links"
  end
end
