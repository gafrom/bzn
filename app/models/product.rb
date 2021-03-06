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
#  rating         :integer
#  feedback_count :integer
#
# Indexes
#
#  index_products_on_category_id  (category_id)
#  index_products_on_remote_id    (remote_id)
#  index_products_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (supplier_id => suppliers.id)
#

class Product < ApplicationRecord
  PROXY_HOST = "http://#{ENV['BZN_HOST_PROD']}".freeze
  MOCK = { title: 'title', price: 100 }

  after_create :set_slug

  has_many :colorations, dependent: :destroy
  has_many :colors, through: :colorations

  has_many :propertings, dependent: :destroy
  has_many :properties, through: :propertings

  has_many :daily_facts
  has_many :hourly_facts

  has_many :pstings, dependent: :destroy,
    foreign_key: :product_remote_id, primary_key: :remote_id
  has_many :sync_tasks, through: :pstings

  attribute :supplier_categories # to avoid deprecation warning
  has_many :pscings, dependent: :destroy
  has_many :supplier_categories, through: :pscings

  has_one :branding, dependent: :destroy
  accepts_nested_attributes_for :branding, update_only: true
  has_one :brand, through: :branding
  delegate :brand_id, to: :branding

  belongs_to :category, optional: true
  belongs_to :supplier

  validates :title, presence: true

  scope :available, -> { where is_available: true }
  scope :unavailable, -> { where is_available: false }

  def self.headers(strategy)
    case strategy
    when :just_stock    then %w[id title price stock]
    when :just_id       then %w[id title category]
    when :just_supplier then %w[id title supplier]
    when :succinct
      %w[remote_id title supplier category orders_count sizes brand
         original_price discount_price coupon_price rating color created_at updated_at]
    end
  end

  def stock
    is_available ? 20 : 0
  end

  def rel_path
    url[0] == ?/ ? url[1..-1] : url
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
      when :just_id       then [[id, title, category&.title]]
      when :just_supplier then [[id, title, supplier.name]]
      when :succinct
        [[remote_id, title, supplier.name, category&.title, sold_count, sizes.available, brand.title,
          original_price, discount_price, coupon_price, rating, color, created_at, updated_at]]
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

  def new_supplier_category=(sup_cat)
    return if !sup_cat || supplier_categories.include?(sup_cat)

    supplier_categories << sup_cat
    attribute_will_change! :supplier_categories
  end

  private

  def row_for(size, is_first_row)
    cat_titles = [supplier_categories.pluck(:name).join(?;)]
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
