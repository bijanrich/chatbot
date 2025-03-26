if Rails.env.production?
  require 'resend'
  Resend.api_key = ENV.fetch('RESEND_API_KEY', 're_7zfsXAJ2_539AmnbwiMMSjfy8FtM63TB')

  # Configure ActionMailer to use Resend in production
  ActionMailer::Base.add_delivery_method :resend, Resend::ActionMailerAdapter
  ActionMailer::Base.delivery_method = :resend
end 