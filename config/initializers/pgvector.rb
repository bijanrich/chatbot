begin
  require 'pgvector'
  
  # Only try to load active_record if it's available
  if defined?(ActiveRecord)
    require 'pgvector/active_record'
    Pgvector.install if defined?(Pgvector.install)
  end
rescue LoadError => e
  warn "Warning: pgvector gem not fully loaded: #{e.message}"
end
