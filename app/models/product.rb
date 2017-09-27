# == Schema Information
#
# Table name: products
#
#  id            :integer          not null, primary key
#  title         :string
#  is_available  :boolean
#  remote_id     :integer
#  price         :integer
#  compare_price :integer
#  category_id   :integer
#  supplier_id   :integer
#  url           :string
#  description   :text
#  slug          :string
#  collection    :string
#  color         :string
#  sizes         :string           default([]), is an Array
#  images        :string           default([]), is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_products_on_category_id  (category_id)
#  index_products_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (supplier_id => suppliers.id)
#

class Product < ApplicationRecord
  after_create :set_slug

  belongs_to :category
  belongs_to :supplier

  def to_csv(&block)
    return csv_rows unless block_given?

    csv_rows.each { |row| yield row }
  end

  def stock
    is_available ? 1 : 0
  end

  private

  def csv_rows
    @csv_rows ||= begin
      sizes.map do |size|
        csv_row_for size
      end
    end
  end

  def csv_row_for(size)
    cat_titles = category.upto_root.pluck :title
    fail IndexError unless cat_titles.count.between? 1, Export::CATEGORIES_DEPTH
    pads_num = Export::CATEGORIES_DEPTH - cat_titles.count

    cat_titles + [nil] * pads_num + [
      id,
      title,
      price,
      compare_price,
      stock,
      description.gsub(/\r/, ''),
      images.join(' '),
      slug,
      supplier.name,
      size,
      color
    ]
  end

  def set_slug
    update_column :slug, Slug[title].concat("-#{id}")
  end
end
