class PsychologicalAnalysis < ApplicationRecord
  belongs_to :chat

  validates :analysis, presence: true
  validates :analyzed_at, presence: true

  # Get the latest analysis for a chat
  def self.latest_for_chat(chat_id)
    where(chat_id: chat_id).order(analyzed_at: :desc).first
  end

  # Update or create analysis for a chat
  def self.update_analysis(chat_id, analysis_text)
    create!(
      chat_id: chat_id,
      analysis: analysis_text,
      analyzed_at: Time.current
    )
  end
end
