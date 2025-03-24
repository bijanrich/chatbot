module Api
  class ChatsController < ApplicationController
    def create
      # TODO: Implement chat creation logic
      render json: { message: "Chat created successfully" }, status: :created
    end

    def message
      # Initialize memory manager
      memory_manager = MemoryManagerService.new(params[:user_id])

      # Store user's message
      memory_manager.process_message(params[:content], 'user')

      # Get memory context
      context = memory_manager.build_context

      # For testing: Return memory information instead of AI response
      response = {
        content: format_memory_response(context),
        timestamp: Time.current.iso8601,
        debug_info: {
          short_term_memory: context[:recent_messages],
          long_term_memory: context[:relevant_facts]
        }
      }

      # Store this response in memory too
      memory_manager.process_message(response[:content], 'assistant')
      
      render json: response
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def format_memory_response(context)
      response = ["Here's what I remember:"]
      
      # Add recent messages
      response << "\nRecent Conversation:"
      context[:recent_messages].each do |msg|
        response << "#{msg[:role].capitalize} (#{msg[:timestamp]}): #{msg[:content]}"
      end

      # Add relevant facts if any
      if context[:relevant_facts].present?
        response << "\nRelevant Facts About You:"
        response.concat(context[:relevant_facts])
      else
        response << "\nNo stored facts yet."
      end

      response.join("\n")
    end
  end
end 