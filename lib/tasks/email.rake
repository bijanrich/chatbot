namespace :email do
  desc "Test sending an email with Resend"
  task test: :environment do
    puts "Testing Resend email delivery..."
    
    # Direct API usage
    result = Resend::Emails.send({
      from: "onboarding@resend.dev",
      to: ENV['TEST_EMAIL'] || "your-test-email@example.com",
      subject: "Hello from Resend",
      html: "<p>Congrats on sending your <strong>first email</strong>!</p>"
    })
    
    puts "Direct API result: #{result.inspect}"
    
    # Check if we have a user to send to
    if User.any?
      user = User.first
      puts "Sending test welcome email to #{user.email}..."
      
      begin
        EmailService.send_welcome_email(user)
        puts "Welcome email sent successfully via ActionMailer!"
      rescue => e
        puts "Error sending welcome email: #{e.message}"
      end
    else
      puts "No users found in the database to send a test welcome email."
    end
    
    puts "Email test completed!"
  end
  
  desc "Send a direct email using Resend service"
  task :send, [:email] => :environment do |t, args|
    email = args[:email] || ENV['TEST_EMAIL'] || "your-test-email@example.com"
    
    puts "Sending direct email to #{email}..."
    
    result = EmailService.send_direct_email(
      from: "onboarding@resend.dev",
      to: email,
      subject: "Test Email from Rake Task",
      html_body: "<h1>Hello from the Rake Task!</h1><p>This email was sent using the EmailService.</p>"
    )
    
    puts "Result: #{result.inspect}"
  end
end 