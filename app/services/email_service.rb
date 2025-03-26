class EmailService
  class << self
    # Send a welcome email to a newly registered user
    # @param user [User] the user to send the welcome email to
    # @return [Hash] the Resend API response
    def send_welcome_email(user)
      NotificationMailer.welcome_email(user).deliver_now
    end

    # Send a direct email using Resend API
    # @param from [String] sender email
    # @param to [String] recipient email
    # @param subject [String] email subject
    # @param html_body [String] HTML content of the email
    # @param text_body [String] text content of the email (optional)
    # @return [Hash] the Resend API response
    def send_direct_email(from:, to:, subject:, html_body:, text_body: nil)
      # Build the email parameters
      params = {
        from: from,
        to: to,
        subject: subject,
        html: html_body
      }
      
      # Add text body if provided
      params[:text] = text_body if text_body.present?
      
      # Send email via Resend API
      Resend::Emails.send(params)
    rescue => e
      Rails.logger.error("Failed to send email: #{e.message}")
      { error: e.message }
    end
  end
end 