class Slug
  def self.[](str)
    Translit.convert(str, :english)
      .downcase.gsub(/[^0-9a-z\s\-]/, '')
      .strip.gsub(/(\s-\s|-\s|\s+)/, '-')    
  end
end
