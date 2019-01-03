# Methods to be implemented for a base class:
# - supplier
#
module Catalogue::WithTrackedProductUpdates
  private

  def synchronize_with(offer, options = {})
    attrs = product_attributes_from offer
    attrs.merge! options
    update_product attrs
  rescue NoMethodError, KeyError, NotImplementedError => ex
    log_failure_for url_from(offer), ex.message
  ensure
    attrs ||= {}
    product = find_product(attrs.merge(options)[:remote_key])
    @processed << product.id if product
  end

  def synchronize(url, product)
    attrs = parse(URI("#{supplier.host}#{url}")).merge! url: url
    update_product attrs, product
  rescue OpenURI::HTTPError, Net::ReadTimeout, Net::OpenTimeout, NotImplementedError => ex
    log_failure_for url, ex.message
  ensure
    @processed << product.id if product
  end

  def url_from(offer)
    offer.css('url').first.text.split(supplier_host).last
  end

  def fresh?(product, modified_at_as_string)
    updated_at = product.updated_at
    updated_at && updated_at > modified_at_as_string.to_date
  end

  def parse(uri)
    content = open(uri, request_headers).read
    page = Nokogiri::HTML content

    product_attributes_from page
  end

  def find_product(key)
    Product.find_or_initialize_by remote_key: key, supplier: supplier
  end

  def update_product(attrs, product = nil)
    product = find_product attrs[:remote_key] unless product

    product.assign_attributes attrs
    was_new_record = product.new_record?
    was_changed    = product.changes if product.changed? || product.branding&.changed?

    saved = product.save
    @processed << product.id

    return log_failure_for attrs[:title], product.errors.messages unless saved

    save_daily_fact(product, was_changed)

    return increment_created product if was_new_record
    return increment_updated product, was_changed if was_changed
    skip product
  rescue NoMethodError, NotImplementedError => ex
    log_failure_for (product.url || attrs[:title]), ex.message
  end

  def save_daily_fact(product, changes = nil)
    fact = DailyFact.find_or_initialize_by created_at: Date.today, product_id: product.id

    attributes_to_save = {
      product:      product, # to avoid db hitting
      remote_id:    product.remote_id,
      category_id:  product.category_id,
      brand_id:     product.brand_id,
      is_available: product.is_available
    }

    if product.is_available?
      # add all other attributes from the product
      attributes_to_save.merge! original_price: product.original_price,
                                discount_price: product.discount_price,
                                coupon_price:   product.coupon_price,
                                sold_count:     product.sold_count,
                                rating:         product.rating,
                                sizes:          product.sizes
    else
      # add only changed attributes
      (changes || {}).keys.each do |field|
        attributes_to_save.merge!(field.to_sym => product.send(field))
      end
    end

    fact.assign_attributes attributes_to_save
    fact.save
  end

  def hide_removed_products
    @processed.delete nil

    all_of_supplier = Product.available.where supplier: supplier
    to_be_hidden = all_of_supplier.where.not id: @processed.to_a

    share = to_be_hidden.size.fdiv all_of_supplier.size
    if share > 0.33
      error = "😱  Attempt to hide more than 33% of all available products "\
              "(requested #{to_be_hidden.size} records, #{(share * 100).round}%). Declined."\
              "\nTo be hidden: #{to_be_hidden.map(&:id).inspect}"
      abort error
    end

    @hidden_count = to_be_hidden.update_all is_available: false
  end

  def increment_created(product)
    log_success_for product.url, :created
    @created_count += 1
  end

  def increment_updated(product, changes)
    log_success_for product.url, :updated, changes
    @updated_count += 1
  end

  def skip(product, touch: true)
    product.touch if touch
    log_success_for product.url, :skipped
    @skipped_count += 1
  end
end
