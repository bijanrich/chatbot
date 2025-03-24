class ExtractMemoryJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    
    # Only extract memories from user messages, skip system/bot messages and commands
    return if message.role != 'user' || message.content.start_with?('/')
    
    begin
      # Extract memories using the MemoryExtractorService
      memories = MemoryExtractorService.new(message).extract_memory_facts
      
      Rails.logger.info("Extracted #{memories.size} memories from message #{message_id}")
    rescue => e
      Rails.logger.error("Error extracting memories from message #{message_id}: #{e.message}\n#{e.backtrace.join("\n")}")
      # Don't re-raise the error since this is a background job
      # and we don't want to block the main flow if memory extraction fails
    end
  end
end 