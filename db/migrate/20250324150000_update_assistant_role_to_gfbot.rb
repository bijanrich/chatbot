class UpdateAssistantRoleToGfbot < ActiveRecord::Migration[7.1]
  def up
    Message.where(role: 'assistant').update_all(role: 'gfbot')
  end

  def down
    Message.where(role: 'gfbot').update_all(role: 'assistant')
  end
end 