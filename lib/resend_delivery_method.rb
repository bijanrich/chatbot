require 'resend'

module ActionMailer
  class Base
    add_delivery_method :resend, Mail::Resend
  end
end

module Mail
  class Resend
    attr_accessor :settings

    def initialize(settings)
      self.settings = settings
      puts "Initializing Resend delivery method with API key: #{settings[:api_key]}"
      Resend.api_key = settings[:api_key]
    end

    def deliver!(mail)
      puts "Attempting to deliver email via Resend..."
      puts "From: #{mail.from.first}"
      puts "To: #{mail.to}"
      puts "Subject: #{mail.subject}"

      # Extract email content
      html_part = mail.html_part ? mail.html_part.body.decoded : nil
      text_part = mail.text_part ? mail.text_part.body.decoded : nil
      html_content = html_part || (mail.content_type =~ /html/ ? mail.body.decoded : nil)
      text_content = text_part || (mail.content_type =~ /plain/ ? mail.body.decoded : nil)

      # Build parameters for Resend
      params = {
        from: mail.from.first,
        to: mail.to,
        subject: mail.subject,
        html: html_content,
        text: text_content
      }.compact

      # Add CC and BCC if present
      params[:cc] = mail.cc if mail.cc
      params[:bcc] = mail.bcc if mail.bcc

      # Add reply-to if present
      params[:reply_to] = mail.reply_to.first if mail.reply_to&.first

      puts "Sending with params: #{params.inspect}"
      
      # Send email via Resend API
      result = Resend::Emails.send(params)
      puts "Resend API response: #{result.inspect}"
      result
    rescue => e
      puts "Error in Resend delivery method: #{e.message}"
      puts "API key being used: #{Resend.api_key}"
      raise "Failed to send email via Resend: #{e.message}"
    end
  end
end 