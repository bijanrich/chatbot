class SettingsController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard'
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    
    if @user.update(user_params)
      redirect_to edit_settings_path, notice: "Settings updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name)
  end
end 