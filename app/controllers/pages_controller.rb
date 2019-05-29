class PagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_page, only: [:edit, :update, :destroy, :remove_cover_image, :distribute, :ads]
  before_action :sudo_can_see_all_pages, only: [:edit, :update, :remove_cover_image, :create, :distribute, :ads]

  def distribute
    @cover_image_alignment = ['vertical', 'horizontal'].map {|r| ["#{r.titlecase}", r]}
    @page.publish = @page.status == 'published'
    @image = @page.cover_image
    if @image.blank?
      @page.build_cover_image
    end
  end

  def ads
    @ad_integrations = @page.ad_integrations
    @page_streams = @page.page_streams
    @ad_integration = AdIntegration.new
  end

  def edit
    if @page.template_page.name == "article"
      redirect_to edit_write_site_story_path(@site, @page, folder_id: @page.folder_id)
    else

      @page.publish = @page.status == 'published'
      @image = @page.cover_image
      if @image.blank?
        @page.build_cover_image
      end
      if @page.template_page.name == "Homepage: Vertical"
        @streams = @page.streams
        @page_stream_16 = @page.streams.where(title: "#{@page.id}_Section_16c_Hero").first
        @page_stream_07 = @page.streams.where(title: "#{@page.id}_Section_7c").first
        @page_stream_04 = @page.streams.where(title: "#{@page.id}_Section_4c").first
        @page_stream_03 = @page.streams.where(title: "#{@page.id}_Section_3c").first
        @page_stream_02 = @page.streams.where(title: "#{@page.id}_Section_2c").first
        @page_stream_cr = @page.streams.where(title: "#{@page.id}_Section_credits").first
        @page_stream_cta = @page.streams.where(title: "#{@page.id}_Section_cta").first
        @page_streamH16 = @page_stream_16.page_streams.where(page_id: @page.id).first
        @page_streamH07 = @page_stream_07.page_streams.where(page_id: @page.id).first
        @page_streamH04 = @page_stream_04.page_streams.where(page_id: @page.id).first
        @page_streamH03 = @page_stream_03.page_streams.where(page_id: @page.id).first
        @page_streamH02 = @page_stream_02.page_streams.where(page_id: @page.id).first
        @page_streamHcr = @page_stream_cr.page_streams.where(page_id: @page.id).first
        @page_streamHcta = @page_stream_cta.page_streams.where(page_id: @page.id).first
        exclude_view_casts = StreamEntity.view_casts.where(stream_id: [@page_stream_16.id, @page_stream_07.id, @page_stream_04.id, @page_stream_03.id, @page_stream_02.id]).pluck(:entity_value)
        @all_cards = @site.view_casts.where.not(id: exclude_view_casts).where(is_autogenerated: false).where(folder_id: @site.folders.active.pluck(:id)).where.not(template_card_id: TemplateCard.where(name: ['toParagraph', "Oxfam IRBF: toCompanyProfile", "Oxfam IRBF: toQuestion", "Oxfam IRBF: toSurveyScores","toData: Rating with drill down", "toData: IRBF Grid", "toData: IRBF Tooltip"])).order([updated_at: :desc, created_at: :desc])
        @all_cards += @site.view_casts.where.not(id: exclude_view_casts).where(template_card_id: TemplateCard.where(name: "toStory")).where(is_autogenerated: true).where(folder_id: @site.folders.active.pluck(:id)).order([updated_at: :desc, created_at: :desc])
        @stream_entity = StreamEntity.new
      end

    end
  end

  def update
    @page.updated_by = current_user.id
    p_params = page_params
    if params[:commit] == 'Publish'
      p_params["status"] = 'published'
    end
    if p_params.has_key?('cover_image_attributes') and !p_params['cover_image_attributes'].has_key?("image")
      p_params.delete('cover_image_attributes')
    end
    from_page = params[:page][:from_page]
    respond_to do |format|
      if @page.update_attributes(p_params)
        format.json { respond_with_bip(@page) }
        format.html {
          if @page.template_page.name == "article" and from_page == "edit_write"
            redirect_to edit_assemble_site_story_path(@site, @page, folder_id: @page.folder_id)
          else
            if @page.template_page.name == "article"
              redirect_to edit_distribute_site_story_path(@site, @page, folder_id: @page.folder_id), notice: 'Page was successfully updated.'
            else
              redirect_to distribute_site_page_path(@site, @page, folder_id: @page.folder_id), notice: 'Page was successfully updated.'
            end
          end
        }
      else
        format.json { respond_with_bip(@page) }
        format.html {
          @ref_series = RefCategory.where(site_id: @site.id, genre: "series", is_disabled: [false, nil]).order(:name).map {|r| ["#{r.name}", r.id]}
          @ref_intersection = RefCategory.where(site_id: @site.id, genre: "intersection", is_disabled: [false, nil]).order(:name).map {|r| ["#{r.name}", r.id]}
          @ref_sub_intersection = RefCategory.where(site_id: @site.id, genre: "sub intersection", is_disabled: [false, nil]).order(:name).map {|r| ["#{r.name}", r.id]}
          @cover_image_alignment = ['vertical', 'horizontal'].map {|r| ["#{r.titlecase}", r]}
          @view_cast = @page.view_cast if @page.view_cast_id.present?
          @page_streams = @page.page_streams
          @page.publish = @page.status == 'published'
          if @page.status != "draft"
            if @page.template_page.name == "Homepage: Vertical"
              if from_page == 'page_distribute'
                @cover_image_alignment = ['vertical', 'horizontal'].map {|r| ["#{r.titlecase}", r]}
                @page.publish = @page.status == 'published'
                @image = @page.cover_image
                if @image.blank?
                  @page.build_cover_image
                end
                flash.now.alert = @page.errors.full_messages
                render "distribute"
              else
                @streams = @page.streams
                @page_stream_16 = @page.streams.where(title: "#{@page.id}_Section_16c_Hero").first
                @page_stream_07 = @page.streams.where(title: "#{@page.id}_Section_7c").first
                @page_stream_04 = @page.streams.where(title: "#{@page.id}_Section_4c").first
                @page_stream_03 = @page.streams.where(title: "#{@page.id}_Section_3c").first
                @page_stream_02 = @page.streams.where(title: "#{@page.id}_Section_2c").first
                @page_stream_cr = @page.streams.where(title: "#{@page.id}_Section_credits").first
                @page_stream_cta = @page.streams.where(title: "#{@page.id}_Section_cta").first
                @page_streamH16 = @page_stream_16.page_streams.where(page_id: @page.id).first
                @page_streamH07 = @page_stream_07.page_streams.where(page_id: @page.id).first
                @page_streamH04 = @page_stream_04.page_streams.where(page_id: @page.id).first
                @page_streamH03 = @page_stream_03.page_streams.where(page_id: @page.id).first
                @page_streamH02 = @page_stream_02.page_streams.where(page_id: @page.id).first
                @page_streamHcr = @page_stream_cr.page_streams.where(page_id: @page.id).first
                @page_streamHcta = @page_stream_cta.page_streams.where(page_id: @page.id).first
                exclude_view_casts = StreamEntity.view_casts.where(stream_id: [@page_stream_16.id, @page_stream_07.id, @page_stream_04.id, @page_stream_03.id, @page_stream_02.id, @page_stream_cr.id, @page_stream_cta.id]).pluck(:entity_value)
                @all_cards = @site.view_casts.where.not(id: exclude_view_casts).where(is_autogenerated: false).where(folder_id: @site.folders.active.pluck(:id)).where.not(template_card_id: TemplateCard.where(name: ['toParagraph', "Oxfam IRBF: toCompanyProfile", "Oxfam IRBF: toQuestion", "Oxfam IRBF: toSurveyScores", "toData: Rating with drill down", "toData: IRBF Grid", "toData: IRBF Tooltip"])).order([updated_at: :desc, created_at: :desc])
                @all_cards += @site.view_casts.where.not(id: exclude_view_casts).where(template_card_id: TemplateCard.where(name: "toStory")).where(is_autogenerated: true).where(folder_id: @site.folders.active.pluck(:id)).order([updated_at: :desc, created_at: :desc])
                @stream_entity = StreamEntity.new
                render :action => "edit", alert: @page.errors.full_messages
              end
            else
              redirect_to edit_write_site_story_path(@site, @page, folder_id: @page.folder_id), alert: @page.errors.full_messages
              return
            end
          end
        }
      end
    end
  end

  def remove_cover_image
    @page.update_attributes(cover_image_id: nil, cover_image_id_7_column: nil)
    redirect_back(fallback_location: site_pages_path(@site, folder_id: (@folder.present? ? @folder.id : nil)), notice: t("ds"))
  end

  def destroy
    f = @page.folder_id
    @page.destroy
    redirect_to site_pages_path(@site, folder_id: f), notice: 'Page was successfully destroyed.'
  end

  private

  def set_page
    @page = Page.friendly.find(params[:id])
  end

    def page_params
      params.require(:page).permit(:id,  :ga_code, :site_id, :folder_id, :folder_id, :headline, :meta_keywords, :meta_description, :summary, :template_page_id, :byline_id, :one_line_concept, :hide_byline,
                                    :reported_from_country, :reported_from_state, :reported_from_district, :reported_from_city,
                                   :cover_image_url, :cover_image_url_7_column, :cover_image_url_facebook, :cover_image_url_square, :cover_image_alignment, :content,
                                   :is_sponsored, :is_interactive, :has_data, :has_image_other_than_cover, :has_audio, :has_video, :status, :published_at, :url, :html_key,
                                   :ref_category_series_id, :ref_category_intersection_id, :ref_category_sub_intersection_id, :view_cast_id, :page_object_url, :created_by,
                                   :updated_by, :english_headline, :due, :description, :cover_image_id_4_column, :cover_image_id_3_column, :cover_image_id_2_column, :cover_image_credit, :share_text_facebook,
                                     :share_text_twitter, :publish, :prepare_cards_for_assembling, :format, :importance, :external_identifier, collaborator_lists: [], cover_image_attributes: [:image, :site_id, :is_cover, :created_by,
                                     :updated_by])
    end
end
