require 'telegram/bot'

class TelegramWebhookController < ActionController::API
  def create
    Rails.logger.info "Received Telegram webhook request with params: #{params.inspect}"
    
    begin
      message = params.dig(:message)
      chat_id = message&.dig(:chat, :id)
      text = message&.dig(:text)

      Rails.logger.info "Received message - chat_id: #{chat_id}, text: #{text}"
      
      if chat_id && text
        # Store the message
        stored_message = Message.create_from_telegram(chat_id, text)
        
        # Queue the job to process and respond to the message
        ProcessTelegramMessageJob.perform_later(stored_message.id)
      end

      # Acknowledge receipt
      head :ok
    rescue => e
      Rails.logger.error "Error in webhook: #{e.message}\n#{e.backtrace.join("\n")}"
      head :ok
    end
  end
end 