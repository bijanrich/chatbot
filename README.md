# AI Chatbot

A Rails-based AI chatbot that interacts with users via Telegram and uses Ollama for AI processing.

## Features

- Telegram bot integration
- Memory extraction and retrieval
- Vector-based semantic search for relevant memories
- Chat-based context building
- Custom model and prompt settings

## Requirements

- Ruby 3.2+ 
- Rails 7.1+
- PostgreSQL with pgvector extension
- Redis (for Sidekiq)
- Ollama (running locally or on a server)

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/aichatbot.git
   cd aichatbot
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Set up the database:
   ```
   rails db:create db:migrate
   ```

4. Configure environment variables in `.env` file:
   ```
   TELEGRAM_API_TOKEN=your_telegram_bot_token
   OLLAMA_API_URL=http://localhost:11434/api
   ```

5. Set up the Telegram webhook:
   ```
   curl -F "url=https://your-domain.com/telegram/webhook" https://api.telegram.org/bot<your_telegram_bot_token>/setWebhook
   ```

   For local development, you can use ngrok to create a tunnel:
   ```
   ngrok http 3000
   ```
   Then use the ngrok URL for the webhook.

6. Start the Rails server:
   ```
   rails server
   ```

7. Start Sidekiq for background jobs:
   ```
   bundle exec sidekiq
   ```

## Commands

The bot supports the following commands:

- `/model <model_name>` - Change the AI model used (default: llama3)
- `/prompt <text>` - Set a custom system prompt
- `/thinking` - Toggle showing the thinking process

## Architecture

The application follows a service-oriented architecture:

- `ProcessTelegramMessageJob` - Handles incoming Telegram messages
- `PromptBuilderService` - Builds context-aware prompts with relevant memories
- `MemoryExtractorService` - Extracts and stores key memories from messages
- `OllamaService` - Communicates with Ollama API for AI responses and embeddings

## Memory System

The chatbot uses a sophisticated memory system:

1. Each user message is processed to extract key memories
2. Memories are stored with vector embeddings for semantic search
3. When generating responses, the system retrieves relevant memories
4. Memories are ranked by relevance and importance

## Development

To contribute to the project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT 