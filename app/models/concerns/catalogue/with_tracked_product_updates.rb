# Methods to be implemented for a base class:
# - supplier
#
module Catalogue::WithTrackedProductUpdates
  private

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

  # in case a product's web page is not modified
  def skip(url)
    @skipped_count += 1
    puts "Processing #{url}... Skipped"
  end

  def parse(uri)
    page = Nokogiri::HTML open(uri)
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
    log_success_for product

    return @created_count += 1 if was_new_record
    return @updated_count += 1 if was_changed
    @skipped_count += 1
  rescue NoMethodError, NotImplementedError => ex
    log_failure_for attrs[:title], ex.message
  end
end
