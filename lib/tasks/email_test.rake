namespace :email do
  desc "Test email delivery by sending a test email"
  task test: :environment do
    puts "Sending test email..."
    
    # Simple mailer for testing
    class TestMailer < ActionMailer::Base
      def test_email
        mail(
          to: "bijan.pourriahi@gmail.com",
          from: "support@fanpilot.app",
          subject: "Test Email from FanPilot",
          body: "This is a test email from FanPilot. If you can see this, email sending is working correctly."
        )
      end
    end
    
    # Store original delivery method
    original_delivery_method = ActionMailer::Base.delivery_method
    
    begin
      # Force SMTP in development
      if Rails.env.development?
        puts "Setting delivery method to SMTP for development..."
        ActionMailer::Base.delivery_method = :smtp
      end
      
      # Display current email settings
      puts "Current ActionMailer settings:"
      puts "delivery_method: #{ActionMailer::Base.delivery_method}"
      puts "smtp_settings: #{ActionMailer::Base.smtp_settings.inspect}"
      puts "perform_deliveries: #{ActionMailer::Base.perform_deliveries}"
      puts "raise_delivery_errors: #{ActionMailer::Base.raise_delivery_errors}"
      
      # Send test email
      email = TestMailer.test_email
      result = email.deliver_now
      puts "Email sent successfully!"
      puts "Email details:"
      puts "To: #{email.to}"
      puts "From: #{email.from}"
      puts "Subject: #{email.subject}"
      puts "Message ID: #{email.message_id}"
    rescue => e
      puts "Error sending email: #{e.message}"
      puts e.backtrace.join("\n")
    ensure
      # Reset delivery method if we changed it
      if Rails.env.development? && original_delivery_method != :smtp
        puts "Resetting delivery method back to #{original_delivery_method}"
        ActionMailer::Base.delivery_method = original_delivery_method
      end
    end
  end

  desc "Test email delivery by sending a test email"
  task test_smtp: :environment do
    puts "Sending test email using SMTP settings..."
    
    # Simple mailer for testing
    class TestMailer < ActionMailer::Base
      def test_email
        mail(
          to: "test@example.com",
          from: "test@fanpilot.app",
          subject: "Test Email from FanPilot",
          body: "This is a test email from FanPilot. If you can see this, email sending is working correctly."
        )
      end
    end
    
    # Display current email settings
    puts "Current ActionMailer settings:"
    puts "delivery_method: #{ActionMailer::Base.delivery_method}"
    puts "smtp_settings: #{ActionMailer::Base.smtp_settings.inspect}"
    puts "perform_deliveries: #{ActionMailer::Base.perform_deliveries}"
    puts "raise_delivery_errors: #{ActionMailer::Base.raise_delivery_errors}"
    
    # Send test email
    begin
      email = TestMailer.test_email
      result = email.deliver_now
      puts "Email sent successfully!"
      puts "Email details:"
      puts "To: #{email.to}"
      puts "From: #{email.from}"
      puts "Subject: #{email.subject}"
      puts "Message ID: #{email.message_id}"
    rescue => e
      puts "Error sending email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
  
  desc "Resend confirmation email for the last registered user"
  task resend_last_confirmation: :environment do
    # Find the last registered user
    last_user = User.order(created_at: :desc).first
    
    if last_user.nil?
      puts "No users found in the database."
      next
    end
    
    puts "Last registered user: #{last_user.email} (created at: #{last_user.created_at})"
    
    # Check if they're already confirmed
    if last_user.confirmed?
      puts "User is already confirmed. Confirmed at: #{last_user.confirmed_at}"
      puts "Do you want to send a new confirmation email anyway? (y/n)"
      answer = STDIN.gets.chomp.downcase
      next unless answer == 'y'
    end
    
    # Force delivery method to SMTP for development
    original_delivery_method = ActionMailer::Base.delivery_method
    begin
      if Rails.env.development?
        puts "Temporarily setting delivery method to SMTP"
        ActionMailer::Base.delivery_method = :smtp
      end
      
      # Send confirmation instructions
      puts "Sending confirmation instructions to #{last_user.email}..."
      last_user.send_confirmation_instructions
      puts "Confirmation instructions sent successfully!"
      
      # Display the confirmation token for debugging
      token = last_user.confirmation_token
      puts "Confirmation token: #{token}"
      puts "Confirmation URL: #{Rails.application.routes.url_helpers.user_confirmation_url(confirmation_token: token, host: 'localhost', port: 3000)}"
      
    ensure
      # Reset delivery method
      if Rails.env.development? && original_delivery_method != :smtp
        puts "Resetting delivery method to #{original_delivery_method}"
        ActionMailer::Base.delivery_method = original_delivery_method
      end
    end
  end
end 