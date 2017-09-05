# == Schema Information
#
# Table name: uploads
#
#  id               :integer          not null, primary key
#  attachment       :string(255)
#  template_card_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer
#  folder_id        :integer
#  created_by       :integer
#  updated_by       :integer
#  upload_errors    :text(65535)
#  filtering_errors :text(65535)
#

class Upload < ApplicationRecord
  #CONSTANTS
  #CUSTOM TABLES
  #GEMS
  #ASSOCIATIONS
  belongs_to :template_card
  belongs_to :folder
  include Associable
  #ACCESSORS
  mount_uploader :attachment, CsvUploader
  #VALIDATIONS
  validates :attachment, presence: true
  validates :folder, presence: true
  #CALLBACKS
  after_create :validate_csv
  #SCOPE

  #OTHER
  def validate_csv
    CsvVerificationWorker.perform_async(self.id)
  end

  def validate_headers
    require 'csv'
    csv_headers = CSV.read(self.attachment.file.file)[0]
    path = Rails.root.join("public/csv_templates/#{self.template_card.name.underscore}.csv")
    template_card_headers = CSV.read(path)[0]
    if csv_headers == template_card_headers
      true
    else
      false
    end
  end
  #PRIVATE
end

