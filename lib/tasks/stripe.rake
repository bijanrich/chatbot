namespace :stripe do
  desc "Start Stripe webhook listener for local development"
  task :webhooks => :environment do
    webhook_url = "http://localhost:3000/stripe/webhook"
    puts "Starting Stripe webhook listener..."
    puts "Forwarding Stripe events to #{webhook_url}"
    puts "Press Ctrl+C to stop"
    
    begin
      # Use stripe CLI (assumes it's installed locally)
      # https://stripe.com/docs/stripe-cli
      system("stripe listen --forward-to #{webhook_url}")
    rescue => e
      puts "Error: #{e.message}"
      puts "Make sure you have the Stripe CLI installed: https://stripe.com/docs/stripe-cli"
    end
  end
  
  desc "Sync plans with Stripe"
  task :sync_plans => :environment do
    puts "Syncing plans with Stripe..."
    count = StripeService.sync_plans
    puts "Successfully synced #{count} plans with Stripe."
  end
end 