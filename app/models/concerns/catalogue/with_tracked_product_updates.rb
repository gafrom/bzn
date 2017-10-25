# Methods to be implemented for a base class:
# - supplier
#
module Catalogue::WithTrackedProductUpdates
  private

  def update_product(attrs)
    product = Product.find_or_initialize_by remote_key: attrs[:remote_key],
                                            supplier: supplier
    product.assign_attributes attrs
    was_new_record = product.new_record?
    was_changed    = product.changes if product.changed?
    return log_failure_for attrs[:title], product.errors.messages unless product.save

    @processed << product.id

    return @created_count += 1 if was_new_record
    return @updated_count += 1 if was_changed
    @skipped_count += 1
  rescue NoMethodError => ex
    log_failure_for attrs[:title], ex.message
  end
end
