# == Schema Information
#
# Table name: properties
#
#  id          :integer          not null, primary key
#  name        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Property < ApplicationRecord
  has_many :propertings, dependent: :destroy
  has_many :products, through: :propertings

  validates :name, presence: true

  def self.from_length(length)
    case length
    when   0.. 84 then find_by! name: 'Мини'    # 78, 83, 87, 88
    when  85..117 then find_by! name: 'Миди'    # 79, A 86, 92, 95, 98, 104
    when 118..999 then find_by! name: 'Макси'   # 121, 128, 153, 138
    end
  end
end
