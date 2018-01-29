# == Schema Information
#
# Table name: site_vertical_navigations
#
#  id                       :integer          not null, primary key
#  site_id                  :integer
#  ref_category_vertical_id :integer
#  name                     :string(255)
#  url                      :text(65535)
#  launch_in_new_window     :boolean
#  created_by               :integer
#  updated_by               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  sort_order               :integer
#

class SiteVerticalNavigation < ApplicationRecord

  #CONSTANTS
  #CUSTOM TABLES
  #GEMS
  #ASSOCIATIONS
  belongs_to :site
  belongs_to :ref_category, class_name: "RefCategory", foreign_key: "ref_category_vertical_id"
  belongs_to :creator, class_name: "User", foreign_key: "created_by"
  belongs_to :updator, class_name: "User", foreign_key: "updated_by"

  #ACCESSORS
  validates :name, presence: true
  validates :url, presence: true, format: {:with => /[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}/ }, allow_blank: true, allow_nil: true, length: { in: 3..240 }

  #CALLBACKS
  before_create :before_create_set
  after_save :after_save_set
  after_destroy :update_site_navigations

  #SCOPE
  #OTHER
  #PRIVATE
  def update_site_navigations
    Thread.new do
      navigation_json = []
      if self.ref_category.navigations.count > 0
        self.ref_category.navigations.each do |nav|
          navigation_json << {"name": nav.name, "url": nav.url, "new_window": nav.launch_in_new_window}
        end
      end
      key = self.ref_category.vertical_header_key
      encoded_file = Base64.encode64(navigation_json.to_json)
      content_type = "application/json"
      resp = Api::ProtoGraph::Utility.upload_to_cdn(encoded_file, key, content_type)
      if self.site.cdn_id != ENV['AWS_CDN_ID']
        Api::ProtoGraph::CloudFront.invalidate(self.site, ["/#{key}"], 1)
      end
      Api::ProtoGraph::CloudFront.invalidate(nil, ["/#{key}"], 1)
      ActiveRecord::Base.connection.close
    end
  end

  private


  def before_create_set
    self.launch_in_new_window = false if self.launch_in_new_window.blank?
    final = SiteVerticalNavigation.where(site_id: self.site_id, ref_category_vertical_id: self.ref_category_vertical_id).order("sort_order DESC").first
    if final.blank?
      self.sort_order = 1
    else
      self.sort_order = final.sort_order + 10
    end
    true
  end

  def after_save_set
    update_site_navigations
  end

end