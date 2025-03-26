require 'resend'

# Set API key
Resend.api_key = 're_XS4hiHPW_xj5MFCk4hUTKLdm6SLKJYY3H'

# Send email
result = Resend::Emails.send({
  from: 'support@fanpilot.app',
  to: 'bijan.pourriahi@gmail.com',
  subject: 'Test Email from FanPilot',
  html: '<p>This is a test email from FanPilot sent via Resend. If you can see this, email sending is working correctly!</p>'
})

puts "Result: #{result.inspect}" 