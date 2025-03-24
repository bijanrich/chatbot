# Chatbot

An AI-powered chatbot service.

## Project Structure

- `web/` - Rails web application for user interface and authentication
- `api/` - FastAPI service for handling chat interactions and LLM integration
- `docker/` - Docker configuration files
- `scripts/` - Utility scripts and tools

## Tech Stack

- **Web Application**: Ruby on Rails
- **API Service**: FastAPI (Python)
- **Databases**: 
  - PostgreSQL (primary database)
  - Redis (session/cache)
- **AI/LLM**: Local GPU support (1080Ti) with Vast.ai scaling option

## Development Setup

1. Install dependencies:
   - Ruby 3.x
   - Python 3.9+
   - PostgreSQL
   - Redis
   - Docker (optional)

2. Set up the web application:
   ```bash
   cd web
   bundle install
   rails db:setup
   ```

3. Set up the API service:
   ```bash
   cd api
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. Start the services:
   ```bash
   # Terminal 1 - Web
   cd web
   rails server

   # Terminal 2 - API
   cd api
   uvicorn main:app --reload

   # Terminal 3 - Redis (if not running)
   redis-server
   ```

## Architecture

The system is split into two main components:

1. **Web Application (Rails)**
   - User authentication
   - Payment processing
   - User interface
   - Session management

2. **API Service (FastAPI)**
   - Chat message handling
   - LLM integration
   - Conversation context management
   - Response generation

## License

Proprietary - All rights reserved 