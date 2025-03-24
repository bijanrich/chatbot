# Disable asset pipeline for API-only application
Rails.application.config.assets_enabled = false if Rails.application.config.respond_to?(:assets_enabled) 