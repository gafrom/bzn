require 'nokogiri'
require 'open-uri'
require 'csv'


# @doc.css('ul.carousel li:not(.jc-active) img:first-child').each do |node|
#   @images << node.attr('src').sub('/tm/', '/big/')
# end


namespace :gepur do
  task :sync do
    catalog = Gepur::Catalog.new
    # catalog.update
    catalog.read
  end
end
