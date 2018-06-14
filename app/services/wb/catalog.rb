module Wb
  class Catalog < ::Catalog
    include Catalogue::WithFile
    include Catalogue::WithLinksScraper
    include Catalogue::WithTrackedProductUpdates

    LINK_SPL_CHR = '?'.freeze
    HREF = 'href'.freeze
    # PARSING_LIMIT = 7000 # pages

    def sync
      scrape_links '/catalog/zhenshchinam/odezhda/platya?pagesize=200', start_page: 1 do |page|
        page.css('#catalog-content>.catalog_main_table>.dtList>a')
            .map { |a_node| a_node.attr(HREF).split(supplier.host)[-1].split(LINK_SPL_CHR)[0] }
      end

      # process_links
      # update_properties_by_title
    end
  end
end
