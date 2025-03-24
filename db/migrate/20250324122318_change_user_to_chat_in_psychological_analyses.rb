class ChangeUserToChatInPsychologicalAnalyses < ActiveRecord::Migration[7.1]
  def change
    # First delete all existing analyses since we're changing the fundamental relationship
    execute "DELETE FROM psychological_analyses"
    
    remove_reference :psychological_analyses, :user
    add_reference :psychological_analyses, :chat, null: false, foreign_key: true
  end
end
