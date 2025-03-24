class OllamaService
  require 'net/http'
  require 'json'
  require 'httparty'
  
  # Use the same URL that was working in the earlier version
  BASE_URL = ENV.fetch('OLLAMA_API_URL', 'http://localhost:11434/api')
  CHAT_URL = "#{BASE_URL}/chat"
  GENERATE_URL = "#{BASE_URL}/generate"
  
  class << self
    def generate_response(messages, model = 'llama3')
      chat(messages: messages, model: model)
    end
    
    def chat(messages:, model: 'llama3')
      uri = URI(CHAT_URL)
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
    
    # Generate embeddings for text using Ollama
    def generate_embedding(text, model = 'llama3')
      return nil if text.blank?

      # Create an embedding prompt specifically for Llama models
      embedding_prompt = "Represent this text for retrieval: #{text}\nReturn only the embedding vector as a JSON array."

      begin
        response = HTTParty.post(
          GENERATE_URL,
          body: {
            model: model,
            prompt: embedding_prompt,
            raw: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        if response.success?
          # First try to extract a proper JSON array
          response_body = response.parsed_response['response'].to_s
          
          # Try to extract JSON array from the response body
          json_array = extract_json_array(response_body)
          
          if json_array.present?
            embedding = JSON.parse(json_array)
            return embedding if embedding.is_a?(Array) && embedding.all? { |e| e.is_a?(Numeric) }
          end
          
          # If can't find a JSON array, try to extract vector using regex pattern matching
          vector_match = response_body.match(/\[[\d\s,.+-]+\]/)
          if vector_match
            begin
              embedding = JSON.parse(vector_match[0])
              return embedding if embedding.is_a?(Array) && embedding.all? { |e| e.is_a?(Numeric) }
            rescue JSON::ParserError => e
              Rails.logger.error("Error parsing embedding vector: #{e.message}")
            end
          end
          
          Rails.logger.error("Failed to extract valid embedding from response: #{response_body}")
          nil
        else
          Rails.logger.error("Embedding generation error: #{response.code} - #{response.message}")
          Rails.logger.error("Response body: #{response.body}")
          nil
        end
      rescue => e
        Rails.logger.error("Exception in generate_embedding: #{e.message}")
        nil
      end
    end

    private
    
    def extract_json_array(text)
      # Find the beginning of the JSON array
      start_index = text.index('[')
      return nil unless start_index
      
      # Track brackets to find matching closing bracket
      open_brackets = 0
      text[start_index..-1].each_char.with_index do |char, i|
        open_brackets += 1 if char == '['
        open_brackets -= 1 if char == ']'
        
        if open_brackets == 0
          # Found the closing bracket, extract the JSON array substring
          return text[start_index..(start_index + i)]
        end
      end
      
      nil
    end
  end
end 