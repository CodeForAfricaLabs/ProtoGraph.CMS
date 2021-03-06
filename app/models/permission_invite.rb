# == Schema Information
#
# Table name: permission_invites
#
#  id                :integer          not null, primary key
#  permissible_id    :integer
#  email             :string(255)
#  ref_role_slug     :string(255)
#  created_by        :integer
#  updated_by        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  permissible_type  :string(255)
#  name              :string(255)
#  create_user       :boolean
#  do_not_email_user :boolean
#

class PermissionInvite < ApplicationRecord

    #CONSTANTS
    #CUSTOM TABLES
    #GEMS
    #CONCERNS
    include Propagatable
    include AssociableBy
    #ASSOCIATIONS
    belongs_to :permissible, polymorphic: true

    #ACCESSOR
    attr_accessor :redirect_url
    #VALIDATIONS
    validates :permissible_type, presence: true
    validates :permissible_id, presence: true
    validates :email, presence: true, format: { with: /\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/ }
    validates :ref_role_slug, presence: true
    validate  :is_unique_row?, on: :create

    #CALLBACKS
    before_create :before_create_set
    #SCOPE
    scope :site_permissions, -> { where(permissible_type: "Site") }
    #OTHER
    #PRIVATE
    private

    def is_unique_row?
        errors.add(:email, "already invited.") if PermissionInvite.where(permissible_type: self.permissible_type, permissible_id: self.permissible_id, email: self.email).first.present?
        true
    end

    def before_create_set
        self.email = self.email.downcase
    end

end
