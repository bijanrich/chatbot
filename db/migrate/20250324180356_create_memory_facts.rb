class CreateMemoryFacts < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_facts do |t|

      t.timestamps
    end
  end
end
