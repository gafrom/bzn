module Catalogue
  module PropertiesUpdateable
    def update_properties_by(urls:)
      puts "\nUpdating properties by url ..." \
           "\nFound #{products_with_no_properties.count} product(s) without " \
           '[Выходная Повседневная Домашняя] properties.'

      products_with_no_properties.each do |product|
        urls.each do |property_name, pattern|
          if product.url =~ pattern
            property = Property.find_by! name: property_name
            break add_property_to_product(product, property)
          end
        end
      end
    end

    def update_properties_by_title
      puts "\nUpdating properties by title ..." \
           "\nFound #{products_with_no_properties.count} product(s) without " \
           '[Выходная Повседневная Домашняя] properties.'

      products_with_no_properties.each do |product|
        property = Property.from_title(product.title)
        next unless property

        add_property_to_product product, property
      end
    end

    private

    def add_property_to_product(product, property)
      return if product.properties.include? property
      puts "Adding property #{property.name} to '#{product.title}' ..."
      product.properties << property
    end

    def products_with_properties
      Product.available.includes(:properties)
             .where(supplier: supplier)
             .where(properties: { name: %w[Выходная Повседневная Домашняя] })
    end

    def products_with_no_properties
      # Product.available.where(supplier: supplier).joins(:propertings).joins(%(LEFT OUTER JOIN "properties" ON "properties"."id" = "propertings"."property_id" AND "properties"."name" IN ('Выходная', 'Повседневная', 'Домашняя'))).where(properties: { id: nil })
      Product.available.where(supplier: supplier).where.not(id: products_with_properties.pluck(:id))
    end
  end
end
