class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    # Store user_type before calling super since it's not a User attribute
    user_type = params[:user_type]
    
    super do |user|
      if user.persisted? && user_type.present?
        case user_type
        when 'creator'
          # For creators, we create an organization automatically
          org = Organization.create!(
            name: "#{user.name}'s Creator Account",
            billing_email: user.email
          )
          user.update(organization: org)
          
          # Create a creator profile
          CreatorProfile.create!(
            organization: org,
            user: user,
            name: user.name,
            onlyfans_username: user.name.parameterize,
            status: 'active'
          )
          
        when 'agency'
          # For agency owners, we create an agency organization
          org = Organization.create!(
            name: "#{user.name}'s Agency",
            billing_email: user.email
          )
          user.update(organization: org)
        end
      end
      # Send welcome email after successful registration
      EmailService.send_welcome_email(user) if user.persisted?
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end
