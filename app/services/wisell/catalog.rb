require 'open-uri'
require 'csv'

module Wisell
  class Catalog < ::Catalog
    include Catalogue::WithSupplier
    include Catalogue::WithLinksFile
    include Catalogue::WithTrackedProductUpdates

    CLOTHES_API_URL = '/bitrix/catalog_export/yandex_wisell_without_models_opt.php'.freeze
    ACCESSORIES_API_URL = '/bitrix/catalog_export/yandex_wisell_bijou_opt.php'.freeze

    def sync
      update if obsolete?
      parse

      puts "Created: #{@created_count}\n" \
           "Updated: #{@updated_count}\n" \
           "Skipped: #{@skipped_count}\n" \
           "Hidden: #{@hidden_count}\n" \
           "Failures: #{@failures_count}"
    end

    private

    def parse
      file = File.open(path_to_links_file).read
      Nokogiri::XML(file).css('offer').each do |offer|
        attrs = product_attributes_from offer
        update_product attrs
      end
    end

    def update
      uri = URI "#{supplier.host}/#{CLOTHES_API_URL}"
      print "Updating catalog file from #{uri}... "
      IO.copy_stream open(uri), path_to_links_file
      puts 'Done'
    end

    def product_attributes_from(offer)
      attrs = {}
      attrs[:remote_key] = offer.attr('id')
      attrs[:title] = offer.attr('name')
      # attrs[:category] = Categorizer.new.from_title attrs[:title]
      # attrs[:price] = offer.css('#formated_price').first.attr('price').to_i
      # desc = offer.css('[itemprop="model"]').first.text
      # attrs[:description] = desc.blank? ? '' : "<p class='fabric'>Состав: #{desc}</p>"
      # attrs[:description] << offer.css('#tab-description').first.to_html.gsub("\n", ' ').squeeze(' ')
      # attrs[:images] = offer.css('#one-image>.item>img')
      #                      .map { |img| img.attr('src').split(supplier.host).second }
      # attrs[:sizes] = offer.css('#product .owq-name').map { |el| el.text }
      attrs[:is_available] = offer.attr('available').to_s == 'true'
      # attrs[:compare_price] = attrs[:price] * 2
      byebug
      # no collection available at the web site
      attrs
    end


  end
end
