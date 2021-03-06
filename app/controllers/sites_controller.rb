class SitesController < ApplicationController

  before_action :authenticate_user!
  before_action :sudo_role_can_site_settings, only: [:edit, :update]

  def remove_favicon
    @site.update_attributes(favicon_id: nil)
    redirect_to edit_site_path(@site)
  end

  def show
    @sites = current_user.sites
    @uncategorized_folders = @site.folders.where("ref_category_vertical_id IS NULL").active.order(:name)
    @archived_folders = @site.folders.inactive.order(:name)
    @all_verticals = @site.ref_categories.where(genre: "series").includes(:folders).order(:name)
  end

  def remove_logo
    @site.update_attributes(logo_image_id: nil)
    redirect_to edit_site_path(@site)
  end

  def create
    @new_site = Site.new(site_params)
    if @new_site.save!
      current_user.create_permission( "Site", @new_site.id, "owner")
      folder = Folder.create({
                                 name: "Test drive here",
                                 created_by: current_user.id,
                                 updated_by: current_user.id,
                                 site_id: @new_site.id,
                                 is_for_stories: false
                             })
      folder = Folder.create({
                                 name: "Trash",
                                 created_by: current_user.id,
                                 updated_by: current_user.id,
                                 is_trash: true,
                                 is_system_generated: true,
                                 site_id: @new_site.id
                             })

      redirect_to site_path(@new_site), notice: t("cs")
    else
      if @new_site.coming_from_new
        render "sites/new"
      else
        @new_site = Site.new
        @user = current_user
        render "users/edit"
      end
    end
  end

  def edit
    if @site.favicon_id.nil? or @site.favicon.nil?
      @site.build_favicon
    end
    if @site.logo_image_id.nil?
      @site.build_logo_image
    end
    @is_admin = true
  end

  def integrations
    @is_admin = true
  end

  def update
    from = params[:site][:from_page]
    site_p = site_params
    unless site_p.has_key?("logo_image_attributes") and site_p["logo_image_attributes"].has_key?("image")
      site_p.delete('logo_image_attributes')
    end
    unless site_p.has_key?("favicon_attributes") and site_p["favicon_attributes"].has_key?("image")
      site_p.delete('favicon_attributes')
    end
    if @site.update(site_p)
      if from == "product_integrations"
        redirect_to integrations_site_path(@site), notice: 'site was successfully updated.'
      else
        redirect_to edit_site_path(@site), notice: 'site was successfully updated.'
      end
    else
      @permission_role = PermissionRole.where.not(slug: 'owner').pluck(:name, :slug)
      if from == "product_integrations"
        render :integrations
      else
        render :edit
      end
    end
  end

  def fetch_new_data
    LcwDataUpdateWorker.perform_at(10.seconds.from_now)
    redirect_back fallback_location: site_path(@site), notice: "The data will be updated shortly."
  end

  private

  def site_params
    params.require(:site).permit(:show_proto_logo, :from_page, :site_id, :name, :domain, :description, :primary_language, :tooltip_on_logo_in_masthead, :default_seo_keywords, :is_lazy_loading_activated, :is_smart_crop_enabled,:house_colour, :reverse_house_colour, :font_colour, :reverse_font_colour, :stream_url, :stream_id, :cdn_provider, :cdn_id, :host, :cdn_endpoint, :client_token, :access_token, :story_card_style, :client_secret, :g_a_tracking_id, :logo_image_id, :favicon_id, :header_background_color, :header_url, :header_positioning, :english_name, :is_english, :story_card_flip, :seo_name, :comscore_code, :gtm_id, :enable_ads, :show_by_site_name, logo_image_attributes: [:image, :site_id, :is_logo, :created_by, :updated_by], favicon_attributes: [:image, :site_id, :is_favicon, :created_by, :updated_by])
  end

end


