# Methods to be implemented for a base class:
# - supplier
#
module Catalogue::WithTrackedProductUpdates
  private

  def synchronize_with(offer, options = nil)
    attrs = product_attributes_from offer
    attrs.merge! options if options
    update_product attrs
  rescue NoMethodError, KeyError, NotImplementedError => ex
    log_failure_for url_from(offer), ex.message
  end

  def url_from(offer)
    offer.css('url').first.text.split(supplier_host).last
  end

  def synchronize(url, product)
    attrs = parse(URI("#{supplier.host}#{url}")).merge! url: url
    update_product attrs, product
  rescue OpenURI::HTTPError => ex
    log_failure_for url, ex.message
  end

  def fresh?(product, modified_at_as_string)
    updated_at = product.updated_at
    updated_at && updated_at > modified_at_as_string.to_date
  end

  def parse(uri)
    content = open(uri, headers).read
    page = Nokogiri::HTML content

    product_attributes_from page
  end

  def update_product(attrs, product = nil)
    unless product
      product = Product.find_or_initialize_by remote_key: attrs[:remote_key],
                                              supplier: supplier
    end

    product.assign_attributes attrs
    was_new_record = product.new_record?
    was_changed    = product.changes if product.changed?
    return log_failure_for attrs[:title], product.errors.messages unless product.save

    @processed << product.id

    return increment_created product if was_new_record
    return increment_updated product if was_changed
    skip product.url
  rescue NoMethodError, NotImplementedError => ex
    log_failure_for attrs[:title], ex.message
  end

  def hide_removed_products
    removed_from_catalog = Product.where(supplier: supplier, is_available: true)
                                  .where.not(id: @processed)
    removed_from_catalog.update_all is_available: false

    @hidden_count = removed_from_catalog.count
  end

  def increment_created(product)
    log_success_for product.url, :created
    @created_count += 1
  end

  def increment_updated(product)
    log_success_for product.url, :updated
    @updated_count += 1
  end

  def skip(url)
    # log_success_for url, :skipped
    @skipped_count += 1
  end
end
