# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  title      :string
#  parent_id  :integer
#  remote_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ApplicationRecord
  has_many :products
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Category', optional: true

  def self.diagram
    puts find(1).show
    nil
  end

  def upto_root
    return [self] unless parent

    parent.upto_root << self
  end

  def show(indent = 0)
    picture = "#{'  ' * indent} => #{id}, # #{title}\n"
    children.each { |child| picture << child.show(indent + 1) }
    picture
  end
end
