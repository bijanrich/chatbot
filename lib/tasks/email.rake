namespace :email do
  desc "Test sending an email with Resend"
  task test: :environment do
    puts "Testing email delivery with Resend..."
    
    begin
      result = Resend::Emails.send({
        from: "support@fanpilot.app",
        to: "bijan.pourriahi@gmail.com",
        subject: "Test Email from FanPilot",
        html: "<p>This is a test email from FanPilot sent via Resend. If you can see this, email sending is working correctly!</p>"
      })
      
      puts "Email sent successfully!"
      puts "Result: #{result.inspect}"
    rescue => e
      puts "Error sending email: #{e.message}"
      puts e.backtrace
    end

    puts "\nTesting local SMTP (Mailcatcher) delivery..."
    
    # Simple mailer for testing local SMTP
    class TestMailer < ActionMailer::Base
      def test_email
        mail(
          to: "bijan.pourriahi@gmail.com",
          from: "support@fanpilot.app",
          subject: "Test Email from FanPilot (via Mailcatcher)",
          body: "This is a test email from FanPilot via Mailcatcher. If you can see this, local SMTP email sending is working correctly!"
        )
      end
    end

    begin
      # Store original settings
      original_settings = {
        delivery_method: ActionMailer::Base.delivery_method,
        smtp_settings: ActionMailer::Base.smtp_settings.dup,
        perform_deliveries: ActionMailer::Base.perform_deliveries,
        raise_delivery_errors: ActionMailer::Base.raise_delivery_errors
      }

      # Configure for local SMTP
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = { address: 'localhost', port: 1025 }
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true

      # Send test email
      email = TestMailer.test_email
      result = email.deliver_now
      
      puts "Local SMTP email sent successfully!"
      puts "Email details:"
      puts "To: #{email.to}"
      puts "From: #{email.from}"
      puts "Subject: #{email.subject}"
      puts "Message ID: #{email.message_id}"
    rescue => e
      puts "Error sending local SMTP email: #{e.message}"
    ensure
      # Restore original settings
      ActionMailer::Base.delivery_method = original_settings[:delivery_method]
      ActionMailer::Base.smtp_settings = original_settings[:smtp_settings]
      ActionMailer::Base.perform_deliveries = original_settings[:perform_deliveries]
      ActionMailer::Base.raise_delivery_errors = original_settings[:raise_delivery_errors]
    end

    puts "\nEmail tests completed!"
  end
  
  desc "Send a direct email using Resend service"
  task :send, [:email] => :environment do |t, args|
    email = args[:email] || ENV['TEST_EMAIL'] || "your-test-email@example.com"
    
    puts "Sending direct email to #{email}..."

    require 'resend'
    Resend.api_key = ENV['RESEND_API_KEY']
    
    result = EmailService.send_direct_email(
      from: "onboarding@resend.dev",
      to: email,
      subject: "Test Email from Rake Task",
      html_body: "<h1>Hello from the Rake Task!</h1><p>This email was sent using the EmailService.</p>"
    )
    
    puts "Result: #{result.inspect}"
  end
end 