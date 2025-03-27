# Initialize Resend API
require 'resend'
Resend.api_key = ENV['RESEND_API_KEY']

# Configure the delivery method only in production
if Rails.env.production?
  ActionMailer::Base.delivery_method = :resend
  ActionMailer::Base.resend_settings = {
    api_key: ENV['RESEND_API_KEY']
  }
end 