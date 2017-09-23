# @doc.css('ul.carousel li:not(.jc-active) img:first-child').each do |node|
#   @images << node.attr('src').sub('/tm/', '/big/')
# end


namespace :gepur do
  desc 'Update products on local machine'
  task sync: :environment do
    catalog = Gepur::Catalog.new

    catalog.read
  end
end
