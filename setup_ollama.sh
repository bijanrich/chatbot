#!/bin/bash

# Function to check if vast CLI is installed
check_vast_cli() {
  if ! command -v vastai &> /dev/null; then
    echo "Error: VastAI CLI is not installed. Please install it first."
    echo "Follow instructions at: https://console.vast.ai/cli"
    exit 1
  fi
}

# Function to get instance info from VastAI
get_vast_instance_info() {
  echo "Getting VastAI instance information..."
  # Get the list of instances and parse out the one that's running
  vast_instances=$(vastai show instances --raw)
  
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
  instance_info=$(vastai show instance $instance_id --raw)
  
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

# Function to run a ssh connection test
test_ssh_connection() {
  echo "Testing SSH connection to my-local-ai..."
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 my-local-ai 'echo "Connection successful"' > /dev/null 2>&1; then
    echo "SSH connection established successfully."
    return 0
  else
    echo "SSH connection failed. The instance may not be ready yet."
    return 1
  fi
}

# Function to wait for SSH connection with timeout
wait_for_ssh_connection() {
  echo "Waiting for VastAI instance to become accessible via SSH..."
  
  # Calculate end time (5 minutes from now)
  local start_time=$(date +%s)
  local timeout=300 # 5 minutes in seconds
  local end_time=$((start_time + timeout))
  local current_time=$(date +%s)
  local attempt=1
  
  while [ $current_time -lt $end_time ]; do
    echo "Attempt $attempt: Checking SSH connection..."
    
    if test_ssh_connection; then
      echo "SSH connection established after $((current_time - start_time)) seconds."
      return 0
    fi
    
    echo "Retrying in 30 seconds... ($(( (end_time - current_time) / 60 )) minutes remaining)"
    sleep 30
    
    current_time=$(date +%s)
    attempt=$((attempt + 1))
  done
  
  echo "⚠️ SSH connection timed out after 5 minutes."
  echo "The VastAI instance might be having issues."
  
  # Ask if user wants to destroy the instance
  read -p "Do you want to destroy the instance? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Destroying instance $instance_id..."
    vastai destroy instance $instance_id
    echo "Instance destroyed. Please try again with a new instance."
  else
    echo "Instance not destroyed. You can manually check the status or try again later."
  fi
  
  # Play alert sound
  play_alert
  
  return 1
}

# Function to play alert sound
play_alert() {
  # Try different methods depending on OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -e "\a" # Terminal bell
    afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || say "Alert: VastAI instance setup failed" 2>/dev/null
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo -e "\a" # Terminal bell
    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || \
    paplay /usr/share/sounds/ubuntu/stereo/bell.ogg 2>/dev/null || \
    spd-say "Alert: VastAI instance setup failed" 2>/dev/null
  else
    # Generic
    echo -e "\a" # Terminal bell
  fi
}

# Function to run commands on the remote host
run_remote_commands() {
  echo "Connecting to my-local-ai to set up Ollama..."
  
  # Make sure the instance is accessible via SSH first
  if ! wait_for_ssh_connection; then
    echo "Failed to establish SSH connection. Exiting."
    exit 1
  fi
  
  echo "Running setup commands on the remote machine..."
  
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
    count=0
    max_attempts=30
    while ! curl -s http://localhost:11434/api/tags >/dev/null; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $max_attempts ]; then
            echo "Timed out waiting for Ollama server to start."
            exit 1
        fi
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

  # Check if the SSH command was successful
  if [ $? -ne 0 ]; then
    echo "⚠️ Error: Failed to set up Ollama on the remote machine."
    echo "Please check the instance status and try again."
    return 1
  fi
  
  return 0
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

# Function to test Ollama API connectivity
test_ollama_api() {
  echo "Testing connection to Ollama API..."
  if curl -s "http://${ssh_host}:11434/api/tags" > /dev/null; then
    echo "✅ Successfully connected to Ollama API!"
    return 0
  else
    echo "⚠️ Could not connect to Ollama API. The server might not be accessible."
    echo "Please check if port 11434 is open and the server is running."
    return 1
  fi
}

# Main execution
check_vast_cli
get_vast_instance_info
update_ssh_config

# Try to run remote commands, with retry logic
if ! run_remote_commands; then
  echo "Failed to run remote commands after multiple attempts."
  echo "Please check your VastAI instance and try again."
  play_alert
  exit 1
fi

update_env_file

# Test Ollama API connectivity
test_ollama_api

echo "🚀 Setup complete! Your application is now configured to use Ollama on your VastAI instance."
echo "📝 Connection details:"
echo "  - SSH: ssh my-local-ai"
echo "  - Ollama API: http://${ssh_host}:11434/api" 