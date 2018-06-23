# == Schema Information
#
# Table name: products
#
#  id             :integer          not null, primary key
#  title          :string
#  is_available   :boolean
#  price          :integer
#  compare_price  :integer
#  category_id    :integer
#  supplier_id    :integer
#  url            :string
#  description    :text
#  slug           :string
#  collection     :string
#  color          :string
#  sizes          :string           default([]), is an Array
#  images         :string           default([]), is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  remote_key     :string
#  length         :integer
#  remote_id      :integer
#  original_price :integer
#  discount_price :integer
#  coupon_price   :integer
#  sold_count     :integer
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
  PROXY_HOST = 'http://151.248.118.98'.freeze
  MOCK = { title: 'title', price: 100 }

  after_create :set_slug

  has_many :colorations, dependent: :destroy
  has_many :colors, through: :colorations

  has_many :propertings, dependent: :destroy
  has_many :properties, through: :propertings

  has_one :branding, dependent: :destroy
  accepts_nested_attributes_for :branding, update_only: true
  has_one :brand, through: :branding

  belongs_to :category
  belongs_to :supplier

  validates :title, presence: true

  scope :available, -> { where is_available: true }
  scope :unavailable, -> { where is_available: false }

  def stock
    is_available ? 20 : 0
  end

  def full_url
    "#{supplier.host}#{url}"
  end

  def sizes
    SizeArray.new super, self
  end

  def proxied_images
    images.map { |image_path| "#{PROXY_HOST}/#{supplier.slug}#{image_path}" }
  end

  def joined_colors
    colors.map(&:title).join '##'
  end

  def rows(strategy)
    @rows ||= begin
      case strategy
      when :just_stock    then [[id, MOCK[:title], MOCK[:price], stock]]
      when :just_id       then [[id, title, category.title]]
      when :just_supplier then [[id, title, supplier.name]]
      when :succinct
        [[remote_id, title, supplier.name, category.title, sizes, brand.title,
          original_price, discount_price, coupon_price, created_at, updated_at]]
      when :full
        is_first_row = true
        sizes.russian.map do |size|
          row = row_for size, is_first_row
          is_first_row = false
          row
        end
      end
    end
  end

  private

  def row_for(size, is_first_row)
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
      (proxied_images.join(' ') if is_first_row),
      slug,
      brand_or_supplier,
      size,
      joined_colors,
      featured_collections,
      properties.pluck(:name).join('##'),
      full_url,
      color&.gsub('+', ' ')
    ]
  end

  def featured_collections
    Collectionizer.build self
  end

  def brand_or_supplier
    return brand.title if brand
    supplier.name
  end

  def set_slug
    update_column :slug, Slug[title].concat("-#{id}")
  end
end
