module WelcomeHelper
  def maybe_add_size(size)
    size = File.size? Export.path_to_file('juice.xlsx')
    return if size.blank?

    " (#{number_to_human_size size})"
  end
end
