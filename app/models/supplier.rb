# == Schema Information
#
# Table name: suppliers
#
#  id         :integer          not null, primary key
#  name       :string
#  host       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Supplier < ApplicationRecord
  STORAGE_PATH = Rails.root.join('storage')
  FILE_SUFFIX  = '.local'.freeze unless Rails.env.production?

  has_many :products

  validates :name, :host, presence: true, uniqueness: true

  delegate :sync_latest, :sync_daily, :sync_hourly, :sync_orders_counts, to: :catalog

  def domain
    name.constantize
  end

  def slug
    name.underscore
  end

  def each_url_for(urls_group_slug)
    return to_enum(:each_url_for, urls_group_slug) unless block_given?

    path = STORAGE_PATH.join "#{slug}_#{urls_group_slug}_urls#{FILE_SUFFIX}"

    File.foreach(path, chomp: true) { |chomped_line| yield chomped_line }
  end

  def catalog
    @catalog ||= domain::Catalog.new
  end

  def self.from_env
    find_by! name: ENV[name.downcase].to_s.camelcase
  end
end
