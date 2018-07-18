# == Schema Information
#
# Table name: remote_data
#
#  id         :integer          not null, primary key
#  remote_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_remote_data_on_remote_id  (remote_id)
#

class RemoteDatum < ApplicationRecord
  validates :remote_id, uniqueness: true
end
