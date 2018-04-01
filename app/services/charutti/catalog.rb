require 'open-uri'
require 'csv'

module Charutti
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithSitemap
    include Catalogue::WithTrackedProductUpdates

    def sync
      extract_sitemap_links '/sitemap.xml' do |url, _|
        short_url = url.split(supplier.host).last
        short_url !~ /\A\/(news\/.*|content\/.*|catalog\/.*|new-sale\/.*|sale\/.*)?\Z/
      end

      process_links
      update_properties_by_title
    end

    private

    def product_attributes_from(page)
      node = page.css('#content .pane-content')
      info = node.css('.b-element_content')

      attrs = {}
      attrs[:title] = info.css('.b-name_element').first.text.strip
      attrs[:category_id] = Categorizer.new(title: attrs[:title]).id_from_title
      attrs[:price] = info.css('.b-element_price').first.text.delete(' ').to_i
      attrs[:sizes] = info.css('.add-action-form>.b-size_block .b-size_block__list_li_title')
                          .map { |el| el.text }      
      desc_node = info.css('.block_description_property')
      desc_node.css('.js-quest-open').remove
      attrs[:description] = desc_node.to_html
                                     .squeeze(' ')
                                     .gsub(/>[\r\n\s]+</, '><')
                                     .squeeze("\t")
      attrs[:images] = node.css('.view-content .tovar-big-image>a')
                           .map { |a_node| a_node.attr('href') }
      attrs[:is_available] = attrs[:price] > 0 && attrs[:sizes].any?
      attrs[:compare_price] = attrs[:price] * 2
      # no color available at the web site
      # no collection available at the web site
      attrs
    end
  end
end
