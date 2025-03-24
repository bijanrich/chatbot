# Allow ngrok hosts in development
Rails.application.config.hosts = [
  IPAddr.new("0.0.0.0/0"),        # All IPv4 addresses
  IPAddr.new("::/0"),             # All IPv6 addresses
  "localhost",
  "127.0.0.1",
  /.*\.ngrok-free\.app/,          # Allow all ngrok-free.app subdomains
  "bfd1-2806-102e-3-4da1-a000-d46c-ec27-a987.ngrok-free.app" # Your specific ngrok URL
] if Rails.env.development? 