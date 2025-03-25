class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  
  # Get a setting value by key
  def self.get(key, default = nil)
    setting = find_by(key: key)
    return default if setting.nil?
    
    # Convert to appropriate type
    case setting.data_type
    when 'integer'
      setting.value.to_i
    when 'float'
      setting.value.to_f
    when 'boolean'
      setting.value.downcase == 'true'
    when 'json'
      JSON.parse(setting.value) rescue default
    else
      setting.value
    end
  end
  
  # Set a setting value
  def self.set(key, value, data_type = 'string')
    # Convert value to string for storage
    string_value = case value
    when Hash, Array
      value.to_json
      data_type = 'json'
    else
      value.to_s
    end
    
    setting = find_by(key: key)
    if setting
      setting.update(value: string_value, data_type: data_type)
    else
      create(key: key, value: string_value, data_type: data_type)
    end
  end
  
  # Get the global prompt
  def self.global_prompt
    get('global_prompt', 'You are a helpful AI assistant.')
  end
  
  # Set the global prompt
  def self.global_prompt=(prompt)
    set('global_prompt', prompt, 'text')
  end
end
