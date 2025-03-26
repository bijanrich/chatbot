class ApplicationController < ActionController::Base
  # Controller with full Rails functionality
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_test_flash, if: -> { params[:test_flash].present? }

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  def set_test_flash
    flash.now[params[:flash_type] || :notice] = params[:test_flash]
  end
end
