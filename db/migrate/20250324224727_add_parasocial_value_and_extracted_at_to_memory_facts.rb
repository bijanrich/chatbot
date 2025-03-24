class AddParasocialValueAndExtractedAtToMemoryFacts < ActiveRecord::Migration[7.1]
  def change
    add_column :memory_facts, :parasocial_value, :integer
    add_column :memory_facts, :extracted_at, :datetime
  end
end
