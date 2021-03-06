# == Schema Information
#
# Table name: feeds
#
#  id                           :integer          not null, primary key
#  ref_category_id              :integer
#  rss                          :text
#  last_refreshed_at            :datetime
#  created_by                   :integer
#  updated_by                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  next_refreshed_scheduled_for :datetime
#  custom_errors                :text
#

class Feed < ApplicationRecord
  
  #CONSTANTS
  #CUSTOM TABLES
  #GEMS
  #CONCERNS
  include AssociableBy
  
  #ASSOCIATIONS
  belongs_to :ref_category
  has_many :feed_links, dependent: :destroy
  
  #ACCESSORS
  #VALIDATIONS
  validates :rss, presence: true, format: {:with => /[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}/ }, length: { in: 9..240 }
  validates :created_by, presence: true
  validates :updated_by, presence: true
  
  #CALLBACKS
  #SCOPE
  #OTHER
  #PRIVATE
  private
  
end
