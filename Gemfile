source "https://rubygems.org"

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease
gem "jbuilder"
gem "active_model_serializers"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Background job processing
gem 'sidekiq', '~> 7.2'

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS)
gem "rack-cors"

# OpenAI API client
gem 'ruby-openai'

# Telegram Bot API client
gem 'telegram-bot-ruby'

# Load environment variables from .env file
gem 'dotenv-rails'

# Use pgvector for vector similarity search

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

gem "sidekiq-scheduler", "~> 5.0"

gem "pgvector", "~> 0.3.2"
