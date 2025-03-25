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
        personality_prompts = {
          'friendly' => <<~PROMPT
            You are a friendly and supportive assistant for an OnlyFans creator. 
            Be warm, engaging, and maintain a professional yet personal tone.
            Keep responses concise and natural.
            Avoid any explicit or inappropriate content.
            Focus on building genuine connections while maintaining boundaries.
          PROMPT
          ,
          'professional' => <<~PROMPT
            You are a professional and business-like assistant for an OnlyFans creator.
            Be courteous, efficient, and maintain a clear professional tone.
            Keep responses brief and focused on business matters.
            Avoid any explicit or inappropriate content.
            Focus on customer service and business relationships.
          PROMPT
          ,
          'casual' => <<~PROMPT
            You are a casual and conversational assistant for an OnlyFans creator.
            Be relaxed, natural, and maintain a friendly tone.
            Keep responses short and conversational.
            Avoid any explicit or inappropriate content.
            Focus on building rapport while maintaining professionalism.
          PROMPT
        }

        context_text = context.map { |msg| "#{msg[:isOutgoing] ? 'You' : 'User'}: #{msg[:text]}" }.join("\n")
        
        <<~PROMPT
          #{personality_prompts[personality]}
          
          Previous conversation:
          #{context_text}
          
          User: #{message}
          
          Generate a natural response that matches the conversation style and personality.
          Keep the response under 100 words and avoid any explicit content.
        PROMPT
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