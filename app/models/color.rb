# == Schema Information
#
# Table name: colors
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Color < ApplicationRecord
  has_many :colorations, dependent: :destroy
  has_many :products, through: :colorations
end
