class AddMessageIdToMemoryFacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :memory_facts, :message, null: true, foreign_key: true
  end
end
