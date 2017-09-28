class ImagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @images = @account.images.order(:created_at).page params[:page]
    @new_image = Image.new
    render layout: "application-fluid"
  end

  def create
    options = image_params
    # tag_list = params["image"]["tag_list"].reject { |c| c.empty? }

    # if tag_list.present?
    #   options[:tag_list] = tag_list
    # end
    options[:created_by] = current_user.id
    @image = Image.new(options)
    if @image.save
      redirect_to account_images_path(@account), notice: "Image added successfully"
    else
      redirect_to account_images_path(@account), alert: @image.errors.full_messages
    end
  end

  def show
    @new_image = Image.new
    @image = Image.where(id: params[:id]).includes(:image_variation).first
    @image_variation = ImageVariation.new
    render layout: "application-fluid"
  end

  private

  def set_image
    @image = Image.find(params[:id]) if params[:id]
  end

  def image_params
    params.require(:image).permit(:account_id, :image, :name, :description, :tags, :tag_list)
  end
end
