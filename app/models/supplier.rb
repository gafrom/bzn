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
  FILE_SUFFIX  = Rails.env.production? ? ''.freeze : '.local'.freeze

  has_many :products
  has_many :categories, class_name: :SupplierCategory
  has_many :daily_report_tasks

  validates :name, :host, presence: true, uniqueness: true

  delegate :logger, :sync_once, :sync_latest, :sync_daily, :sync_hourly,
           :sync_orders_counts, to: :catalog

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

  def self.main
    find(ENV['MAIN_SUPPLIER_ID'])
  end

  def wide_categories_by_groups
    path = STORAGE_PATH.join "#{slug}_wide_sync_urls_by_groups#{FILE_SUFFIX}"

    File.foreach(path, chomp: true).to_a.reduce({}) do |hsh, line|
      cat_name, *cats = line.split(?,)
      hsh[cat_name] = cats

      hsh
    end
  end

  def categories_mapping
    @categories_mapping ||= begin
      path = STORAGE_PATH.join "#{slug}_entire_sync_urls_mapping#{FILE_SUFFIX}"

      temp = {}
      File.foreach(path, chomp: true) do |line|
        cat, text_with_others = line.split(' => ')
        temp[text_with_others] = cat.split(?,)
      end

      hsh = {}
      categories.each do |supcat|
        _, cat = temp.find { |text, _| text.include?(supcat.name) }
        raise "Cannot find SupplierCategory: #{supcat.name}" unless cat

        hsh[supcat] = cat
      end

      hsh
    end
  end
end
