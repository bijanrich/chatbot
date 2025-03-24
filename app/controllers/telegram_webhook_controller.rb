class TelegramWebhookController < ActionController::API
  # No need for skip_before_action :verify_authenticity_token with ActionController::API
  
  def create
    # Parse the incoming webhook data
    data = JSON.parse(request.body.read)
    
    # Log the incoming webhook for debugging
    Rails.logger.info("Received Telegram webhook: #{data.inspect}")
    
    # Check if this is a message
    if data['message'] && data['message']['text']
      # Extract the message content and chat ID
      message_text = data['message']['text']
      chat_id = data['message']['chat']['id']
      
      Rails.logger.info("Processing message: '#{message_text}' from chat ID: #{chat_id}")
      
      # Process the message asynchronously
      ProcessTelegramMessageJob.perform_later(message_text, chat_id)
    end
    
    # Return a success response
    render json: { status: 'ok' }
  end
end 