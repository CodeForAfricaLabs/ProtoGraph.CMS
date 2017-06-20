# == Schema Information
#
# Table name: template_data
#
#  id                  :integer          not null, primary key
#  account_id          :integer
#  name                :string(255)
#  elevator_pitch      :string(255)
#  description         :text(65535)
#  global_slug         :string(255)
#  is_current_version  :boolean
#  slug                :string(255)
#  version_series      :string(255)
#  previous_version_id :integer
#  version_genre       :string(255)
#  version             :string(255)
#  change_log          :text(65535)
#  status              :string(255)
#  publish_count       :integer
#  is_public           :boolean
#  git_url             :text(65535)
#  git_branch          :string(255)      default("master")
#  created_by          :integer
#  updated_by          :integer
#  api_key             :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class TemplateDatum < ApplicationRecord

    include Versionable
    include Associable
    #CONSTANTS
    CDN_BASE_URL = "#{ENV['AWS_S3_ENDPOINT']}/Schemas"
    #CUSTOM TABLES
    #GEMS
    require 'version'
    extend FriendlyId
    friendly_id :slug_candidates, use: :scoped, scope: [:account_id]

    #ASSOCIATIONS
    belongs_to :account
    belongs_to :creator, class_name: "User", foreign_key: "created_by"
    belongs_to :updator, class_name: "User", foreign_key: "updated_by"
    has_many :template_cards

    #ACCESSORS
    #VALIDATIONS
    validates :account_id, presence: true
    validates :name, presence: true
    validates :created_by, presence: true
    validates :updated_by, presence: true
    validates :git_url, presence: true, format: {with: /(^git@)(.+)(:)(.+)(\/)(.+)(.git$)/}

    #CALLBACKS
    before_create :before_create_set
    after_create :after_create_set

    #SCOPE
    #OTHER
    #TODO: Write a background job to connect to the git repo and the git branch, and upload the file from /build/#version_no./ folder


    def slug_candidates
        ["#{self.name}-#{self.version.to_s}"]
    end

    def current_version
        TemplateDatum.where(global_slug: self.global_slug, is_current_version: true).first
    end

    def deep_copy_across_versions
        p                           = self.previous
        v                           = p.version.to_s.to_version
        if self.version_genre == "major"
            self.version            = v.bump!(:major).to_s
        elsif self.version_genre == "minor"
            self.version            = v.bump!(:minor).to_s
        elsif self.version_genre == "bug"
            self.version            = v.bump!.to_s
        end
        self.account_id             = p.account_id
        self.name                   = p.name
        self.global_slug            = p.global_slug
        self.is_current_version     = false
        self.is_public              = p.is_public
        self.version_series         = self.version.to_s.to_version.to_a[0]
        self.description            = p.description
        self.elevator_pitch         = p.elevator_pitch
        self.api_key                = p.api_key
    end

    def can_ready_to_publish?
        if self.json_schema.file_url.present? and self.sample_json.file_url.present? and self.elevator_pitch.present? and self.description.present? and self.change_log.present?
            return true
        end
        return false
    end

    def is_connected?
        self.template_cards.where(status: "Published").first.present? ? true : false
    end

    def files
        {
            "schema": "#{schema_json}",
            "sample": "#{TemplateDatum::CDN_BASE_URL}/#{self.name}/#{self.version}/sample.json"
        }
    end

    def schema_json
        "#{TemplateDatum::CDN_BASE_URL}/#{self.name}/#{self.version}/schema.json"
    end

    #PRIVATE
    private

    def should_generate_new_friendly_id?
        slug.blank? || name_changed?
    end

    def before_create_set
        self.status = "Draft"
        self.publish_count = 0
        if self.previous_version_id.blank?
            self.global_slug = self.name.parameterize
            self.is_current_version = true
            self.version_series = "0"
            self.previous_version_id = nil
            self.version_genre = "major"
            self.version = "0.0.1"
            self.is_public = false
            self.api_key = SecureRandom.hex(24)
        end
        true
    end

    def after_create_set
        true
    end

end
