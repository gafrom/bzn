# == Schema Information
#
# Table name: brands
#
#  id          :integer          not null, primary key
#  title       :string
#  description :text
#

class Brand < ApplicationRecord
  has_many :brandings, dependent: :destroy
  has_many :products, through: :brandings
end
