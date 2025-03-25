#!/bin/bash

# Function to check if vast CLI is installed
check_vast_cli() {
  if ! command -v vast &> /dev/null; then
    echo "Error: VastAI CLI is not installed. Please install it first."
    echo "Follow instructions at: https://console.vast.ai/cli"
    exit 1
  fi
}

# Function to get instance info from VastAI
get_vast_instance_info() {
  echo "Getting VastAI instance information..."
  # Get the list of instances and parse out the one that's running
  vast_instances=$(vast show instances --raw)
  
  # Check if we got any instances
  if [ -z "$vast_instances" ]; then
    echo "No VastAI instances found. Please ensure you have an active instance."
    exit 1
  fi
  
  # Parse the JSON to get the first running instance
  instance_id=$(echo "$vast_instances" | grep -o '"id": [0-9]*' | head -1 | awk '{print $2}')
  if [ -z "$instance_id" ]; then
    echo "Failed to find a running instance ID."
    exit 1
  fi
  
  echo "Found instance ID: $instance_id"
  
  # Get the specific instance info
  instance_info=$(vast show instance $instance_id --raw)
  
  # Extract SSH info
  ssh_host=$(echo "$instance_info" | grep -o '"ssh_host": "[^"]*"' | cut -d'"' -f4)
  ssh_port=$(echo "$instance_info" | grep -o '"ssh_port": [0-9]*' | awk '{print $2}')
  
  if [ -z "$ssh_host" ] || [ -z "$ssh_port" ]; then
    echo "Failed to extract SSH connection details from VastAI."
    exit 1
  fi
  
  echo "VastAI instance SSH details:"
  echo "  Host: $ssh_host"
  echo "  Port: $ssh_port"
}

# Function to update SSH config
update_ssh_config() {
  ssh_config_file="$HOME/.ssh/config"
  
  # Create SSH config directory if it doesn't exist
  mkdir -p "$HOME/.ssh"
  
  # Check if my-local-ai entry already exists
  if grep -q "Host my-local-ai" "$ssh_config_file" 2>/dev/null; then
    # Update existing entry
    sed -i.bak "/Host my-local-ai/,/^\s*$/c\\
Host my-local-ai\\
  HostName $ssh_host\\
  Port $ssh_port\\
  User root\\
  StrictHostKeyChecking no\\
  UserKnownHostsFile=/dev/null\\
" "$ssh_config_file"
  else
    # Add new entry
    cat >> "$ssh_config_file" << EOF

Host my-local-ai
  HostName $ssh_host
  Port $ssh_port
  User root
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
  fi
  
  echo "SSH config updated. You can now connect using: ssh my-local-ai"
}

# Function to run commands on the remote host
run_remote_commands() {
  echo "Connecting to my-local-ai to set up Ollama..."
  
  # SSH command that installs and configures Ollama on the remote machine
  ssh -o StrictHostKeyChecking=no my-local-ai << 'EOF'
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

echo "Setup complete! Ollama is running and model is ready on the remote machine."
EOF
}

# Function to update local env file with remote details
update_env_file() {
  env_file=".env"
  
  # Create .env file if it doesn't exist
  touch "$env_file"
  
  # Update OLLAMA_API_URL
  if grep -q "OLLAMA_API_URL=" "$env_file"; then
    sed -i.bak "s|OLLAMA_API_URL=.*|OLLAMA_API_URL=http://${ssh_host}:11434/api|g" "$env_file"
  else
    echo "OLLAMA_API_URL=http://${ssh_host}:11434/api" >> "$env_file"
  fi
  
  echo "Updated .env file with remote Ollama API URL"
}

# Main execution
check_vast_cli
get_vast_instance_info
update_ssh_config
run_remote_commands
update_env_file

echo "🚀 Setup complete! Your application is now configured to use Ollama on your VastAI instance."
echo "📝 Connection details:"
echo "  - SSH: ssh my-local-ai"
echo "  - Ollama API: http://${ssh_host}:11434/api" 