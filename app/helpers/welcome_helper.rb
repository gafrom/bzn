module WelcomeHelper
  def file_description(filname)
    path = Export.path_to_file(filname)
    size = File.size? path
    return if size.blank?

    "#{number_to_human_size size}, #{I18n.l(File.mtime(path), format: :succinct)}"
  end
end
