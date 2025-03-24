class ExtractMemoryJob < ApplicationJob
  queue_as :default

  def perform(chat_id)
    chat = Chat.find_by(id: chat_id)
    return unless chat
    
    # Extract memories from the chat
    begin
      service = MemoryExtractorService.new
      service.extract_memories(chat.id)
      Rails.logger.info("Successfully extracted memories for chat #{chat.id}")
    rescue => e
      Rails.logger.error("Failed to extract memories: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end 