class AnalyzeUserPsychologyJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'

  OLLAMA_URL = 'http://192.168.2.2:11434/api/generate'
  
  def self.analysis_logger
    @@analysis_logger ||= Logger.new(Rails.root.join('log', 'psychological_analysis.log')).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{msg}\n"
      end
    end
  end

  def perform(chat_id)
    # Get all messages for this chat
    messages = Message.where(chat_id: chat_id)
                     .where(role: 'user')
                     .order(created_at: :asc)
                     .pluck(:content)
    
    return if messages.empty?

    begin
      # Prepare the prompt for psychological analysis
      prompt = <<~PROMPT
        Based on the following user messages, provide a psychological analysis of the user.
        Focus on:
        1. Communication style and patterns
        2. Emotional expression and regulation
        3. Relationship dynamics and attachment style
        4. Personal values and priorities
        5. Potential areas for growth or support

        User Messages:
        #{messages.join("\n")}

        Please provide a thoughtful, professional analysis while maintaining ethical considerations and privacy.
      PROMPT

      # Call Ollama API for analysis
      analysis_text = call_ollama(prompt)

      # Store the analysis
      PsychologicalAnalysis.update_analysis(chat_id, analysis_text)

      self.class.analysis_logger.info({
        chat_id: chat_id,
        message_count: messages.size,
        timestamp: Time.current.iso8601,
        status: 'success'
      }.to_json)

    rescue => e
      self.class.analysis_logger.error({
        chat_id: chat_id,
        error: e.message,
        backtrace: e.backtrace.join("\n"),
        timestamp: Time.current.iso8601
      }.to_json)

      raise # Re-raise the error to trigger Sidekiq retry
    end
  end

  private

  def call_ollama(prompt)
    uri = URI(OLLAMA_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180  # Increase timeout to 3 minutes for longer analysis
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    payload = {
      model: 'gfbot',
      prompt: prompt,
      stream: false
    }
    
    request.body = payload.to_json

    response = http.request(request)
    
    # Log the raw response
    self.class.analysis_logger.info({
      prompt: prompt,
      response_code: response.code,
      response_body: response.body,
      timestamp: Time.current.iso8601
    }.to_json)
    
    JSON.parse(response.body)['response']
  end
end
