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
    
    build_resource(sign_up_params)
    
    if resource.save
      if user_type.present?
        begin
          case user_type
          when 'creator'
            # For creators, we create an organization automatically
            org = Organization.create!(
              name: "#{resource.name}'s Creator Account",
              billing_email: resource.email
            )
            resource.update(organization: org)
            
            # Create a creator profile
            creator_profile = CreatorProfile.new(
              organization: org,
              user: resource,
              name: resource.name,
              onlyfans_username: resource.name.parameterize,
              status: 'active'
            )
            
            unless creator_profile.save
              # If creator profile fails to save, destroy the user and org
              org.destroy
              resource.destroy
              
              # Add errors to the resource
              creator_profile.errors.full_messages.each do |msg|
                resource.errors.add(:base, msg)
              end
              
              clean_up_passwords resource
              set_minimum_password_length
              respond_with resource and return
            end
            
          when 'agency'
            # For agency owners, we create an agency organization
            org = Organization.create!(
              name: "#{resource.name}'s Agency",
              billing_email: resource.email
            )
            resource.update(organization: org)
          end
        rescue => e
          # If anything fails, destroy the user and org if they exist
          org&.destroy
          resource.destroy
          
          # Add error message
          resource.errors.add(:base, "Failed to complete registration: #{e.message}")
          clean_up_passwords resource
          set_minimum_password_length
          respond_with resource and return
        end
      end

      if is_navigational_format?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        end
      end

      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # The path used after sign up
  def after_sign_up_path_for(resource)
    root_path
  end
end
