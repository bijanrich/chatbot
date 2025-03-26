module Api
  module V1
    class OnlyfansMessagesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :validate_request

      def generate_response
        message = params[:message]
        personality = params[:personality]
        context = params[:context] || []

        # Generate response using your existing AI logic
        response = generate_ai_response(message, personality, context)
        
        render json: { response: response }
      end

      private

      def validate_request
        # Add any validation logic here if needed
        true
      end

      def generate_ai_response(message, personality, context)
        prompt = build_prompt(message, personality, context)
        
        # Use your existing AI service to generate the response
        # This assumes you have an AI service configured
        response = AiService.generate_response(prompt)
        
        # Clean up the response to ensure it's natural and matches the personality
        clean_response(response)
      end

      def build_prompt(message, personality, context)
        context_text = context.map { |msg| "#{msg[:isOutgoing] ? 'You' : 'User'}: #{msg[:text]}" }.join("\n")
      end

      def clean_response(response)
        # Remove any potential explicit content or inappropriate language
        response.gsub(/[^\w\s.,!?-]/i, '')
               .gsub(/\s+/, ' ')
               .strip
      end
    end
  end
end 