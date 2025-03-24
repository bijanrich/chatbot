begin
  require 'pgvector'
rescue LoadError => e
  warn "Warning: pgvector gem not loaded: #{e.message}"
end

# This will be executed when ActiveRecord is available
ActiveSupport.on_load(:active_record) do
  begin
    # Add vector support to PostgreSQL
    connection = ActiveRecord::Base.connection
    unless connection.extension_enabled?('vector')
      connection.enable_extension('vector') rescue nil
    end
  rescue => e
    warn "Warning: Error enabling vector extension: #{e.message}"
  end
end
