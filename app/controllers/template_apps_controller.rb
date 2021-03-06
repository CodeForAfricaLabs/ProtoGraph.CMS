class TemplateAppsController < ApplicationController
  
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :sudo_role_can_site_settings, only: [:edit, :update]
  before_action :set_template_app, only: [:show, :edit, :update, :destroy]

  def index
    @q = @site.template_apps.ransack(params[:q])
    @template_apps = @q.result.page(params[:page]).per(10)
  end

  def show
  end

  def edit
  end

  def update
    @template_app.updated_by = current_user.id
    if @template_app.update(template_app_params)
      redirect_to @template_app, notice: 'Template app was successfully updated.'
    else
      render :edit 
    end
  end

  private

    def set_template_app
      @template_app = TemplateApp.friendly.find(params[:id])
    end

    def template_app_params
      params.require(:template_app).permit(:name, :genre, :pitch, :description, :is_public, :installs, :views, :created_by, :updated_by, :change_log)
    end
end
