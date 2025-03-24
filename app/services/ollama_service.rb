class OllamaService
  require 'net/http'
  require 'json'
  
  # Use the same URL that was working in the earlier version
  OLLAMA_URL = 'http://127.0.0.1:11434/api/chat'
  
  class << self
    def chat(messages:, model: 'llama3')
      uri = URI(OLLAMA_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120  # Increase timeout to 2 minutes
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      
      payload = {
        model: model,
        messages: messages,
        stream: false  # Disable streaming to get a single response
      }
      
      request.body = payload.to_json

      # Log what we're about to send
      Rails.logger.info("Sending request to Ollama: #{request.body}")

      begin
        response = http.request(request)
        
        # Log response details
        Rails.logger.info("Ollama response code: #{response.code}")
        
        unless response.is_a?(Net::HTTPSuccess)
          raise "Ollama API returned non-200 status: #{response.code} - #{response.body}"
        end

        begin
          parsed_response = JSON.parse(response.body)
        rescue JSON::ParserError => e
          # If we got a streaming response despite asking for non-streaming,
          # try to parse the last complete JSON object
          if response.body.include?('{"model":"')
            json_objects = response.body.split("\n").select { |line| line.start_with?('{"model":"') }
            last_response = JSON.parse(json_objects.last)
            parsed_response = last_response
          else
            Rails.logger.error("Failed to parse Ollama response: #{e.message}")
            Rails.logger.error("Raw response was: #{response.body.inspect}")
            raise "Invalid JSON response from Ollama: #{e.message}"
          end
        end

        # Extract the response text from either format
        response_text = if parsed_response['response']
          parsed_response['response']
        elsif parsed_response['message'] && parsed_response['message']['content']
          parsed_response['message']['content']
        else
          raise "Unexpected response format: #{parsed_response.inspect}"
        end

        # Handle empty or invalid response
        if response_text.nil? || response_text.strip.empty?
          error_msg = "Empty response from Ollama: #{parsed_response.inspect}"
          Rails.logger.error(error_msg)
          raise error_msg
        end
        
        response_text.strip
      rescue => e
        Rails.logger.error("Error in OllamaService.chat: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise
      end
    end
  end
end 