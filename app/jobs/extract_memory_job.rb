class ExtractMemoryJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message
    return unless message.role == 'user'  # Only extract memories from user messages
    
    chat = message.chat
    return unless chat
    
    # Extract memories from the message
    begin
      service = MemoryExtractorService.new(chat)
      service.extract_memory_facts(message)
    rescue => e
      Rails.logger.error("Failed to extract memories: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end 