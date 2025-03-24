require 'telegram/bot'

token = ENV['TELEGRAM_BOT_TOKEN']
Rails.logger.info "Found Telegram bot token: #{!token.nil? && !token.empty?}"

if token.nil? || token.empty?
  Rails.logger.error "TELEGRAM_BOT_TOKEN is not set!"
else
  TELEGRAM_BOT = Telegram::Bot::Client.new(token)
  
  # Verify the bot token works
  begin
    bot_info = TELEGRAM_BOT.api.get_me
    Rails.logger.info "Bot initialized successfully: #{bot_info}"
  rescue => e
    Rails.logger.error "Failed to initialize bot: #{e.message}"
  end
end 