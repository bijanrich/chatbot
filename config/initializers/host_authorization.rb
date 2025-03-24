# Be sure to restart the server when you modify this file.

# Allow requests from Docker containers in development
if Rails.env.development?
  Rails.application.config.hosts = [
    IPAddr.new("0.0.0.0/0"),        # All IPv4 addresses
    IPAddr.new("::/0"),             # All IPv6 addresses
    "localhost",
    "api",
    "api:3000",
    "web-client",
    "web-client:5173"
  ]
end 