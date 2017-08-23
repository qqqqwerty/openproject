class DisplayAsController < ApplicationController
  # this is necessary if you want the project menu in the sidebar for your view
  # before_filter :find_optional_project, only: :index

  before_action :require_admin
  layout 'admin'
  
  def index
    @user_name = User.current.getUsedUserName
    respond_to do |format|
      format.html
    end
  end

  def new
    @new_user_id = User.current.id
    @user_id = User.current.used_user
    @users = []
    user_objects = User.order(:firstname)
    user_objects.each do |user_object|
      @users.push([user_object.to_s, user_object.id])
    end
  end

  def create
    user_id = params[:user_id].to_i
    target_user = User.find_by_id(user_id)
    if target_user != nil && !target_user.blank?
      User.current.update_attribute('used_user', user_id)
      flash[:notice] = t(:'display_as.used_user_updated')
      redirect_to action: 'index'
    else
      flash[:error] = t(:'display_as.used_user_not_found')
      redirect_to action: 'new'
    end
  end

  private
  
end
