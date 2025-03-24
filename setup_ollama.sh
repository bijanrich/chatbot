#!/bin/bash

# Check if Ollama is already installed
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    # Wait for installation to complete
    sleep 5
else
    echo "Ollama is already installed"
fi

# Check if Ollama server is already running
if curl -s http://localhost:11434/api/tags >/dev/null; then
    echo "Ollama server is already running"
else
    echo "Starting Ollama..."
    # Kill any existing Ollama processes
    pkill ollama || true
    sleep 2
    
    # Start Ollama with explicit host binding
    export OLLAMA_HOST=0.0.0.0
    ollama serve &
    
    # Wait for Ollama server to start
    echo "Waiting for Ollama server to start..."
    while ! curl -s http://localhost:11434/api/tags >/dev/null; do
        sleep 1
    done
fi

# Check if model is already pulled
if ! curl -s http://localhost:11434/api/tags | grep -q "mistral-small"; then
    echo "Pulling mistral-small model..."
    ollama pull mistral-small
else
    echo "mistral-small model is already pulled"
fi

echo "Setup complete! Ollama is running and model is ready" 