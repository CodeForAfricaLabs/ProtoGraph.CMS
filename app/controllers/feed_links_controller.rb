class FeedLinksController < ApplicationController

  before_action :authenticate_user!
  before_action :set_ref_category, :set_feed_link

  def create_view_cast
    @feed_link.temp_headline = feeds_params[:temp_headline]
    unless @feed_link.view_cast_id.present?
      @feed_link.create_or_update_view_cast
    end
    redirect_to site_ref_category_feeds_path(@site, @ref_category), notice: "Link will be added tot feed shortly"
  end

  private

    def set_ref_category
      @ref_category = RefCategory.friendly.find(params[:ref_category_id])
    end

    def set_feed_link
      @feed_link = FeedLink.find(params[:id])
    end

    def feeds_params
      params.require(:feed_link).permit(:ref_category_id, :link, :headline, :published_at, :description, :cover_image, :author, :temp_headline)
    end


end
