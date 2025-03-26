class StripeService
  class << self
    # Create a checkout session for subscription
    def create_checkout_session(plan_id:, customer_email:, success_url:, cancel_url:, organization:)
      Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        line_items: [{
          price: plan_id,
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: "#{success_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_url,
        client_reference_id: organization.id,
        customer_email: customer_email,
        metadata: {
          organization_id: organization.id,
          plan_id: plan_id
        }
      })
    end
    
    # Retrieve a checkout session
    def retrieve_session(session_id)
      Stripe::Checkout::Session.retrieve(session_id)
    end
    
    # Create or update subscription
    def process_subscription(organization, session_id)
      session = retrieve_session(session_id)
      subscription_id = session.subscription
      
      # Find plan by price ID
      plan = Plan.find_by(stripe_price_id: session.metadata.plan_id)
      
      subscription = organization.build_subscription(
        stripe_subscription_id: subscription_id,
        plan_name: plan&.name,
        status: 'active'
      )
      
      subscription.save
      subscription
    end
    
    # Cancel a subscription
    def cancel_subscription(subscription)
      return false unless subscription.stripe_subscription_id.present?
      
      begin
        stripe_subscription = Stripe::Subscription.update(
          subscription.stripe_subscription_id,
          { cancel_at_period_end: true }
        )
        
        subscription.update(status: 'canceled')
        true
      rescue Stripe::StripeError => e
        Rails.logger.error("Failed to cancel subscription: #{e.message}")
        false
      end
    end
    
    # Create plans in Stripe from local database
    def sync_plans
      Plan.all.each do |plan|
        next if plan.stripe_price_id.present?
        
        begin
          stripe_product = Stripe::Product.create({
            name: "FanPilot #{plan.name}",
            description: plan.description
          })
          
          stripe_price = Stripe::Price.create({
            product: stripe_product.id,
            unit_amount: (plan.amount * 100).to_i, # Convert to cents
            currency: 'usd',
            recurring: {
              interval: plan.interval
            }
          })
          
          plan.update(stripe_price_id: stripe_price.id)
          Rails.logger.info("Created Stripe price for #{plan.name}: #{stripe_price.id}")
        rescue Stripe::StripeError => e
          Rails.logger.error("Failed to create Stripe price for #{plan.name}: #{e.message}")
        end
      end
    end
    
    # Handle a webhook event for checkout.session.completed
    def handle_checkout_completed(event)
      session = event.data.object
      
      # Find the organization from metadata
      organization_id = session.client_reference_id
      organization = Organization.find_by(id: organization_id)
      
      return unless organization
      
      # Process the subscription
      process_subscription(organization, session.id)
    end
    
    # Handle a webhook event for customer.subscription.updated
    def handle_subscription_updated(event)
      stripe_subscription = event.data.object
      
      # Find the subscription in our system
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription
      
      # Update subscription details
      subscription.update(
        current_period_end: Time.at(stripe_subscription.current_period_end),
        status: stripe_subscription.status
      )
    end
    
    # Handle a webhook event for customer.subscription.deleted
    def handle_subscription_deleted(event)
      stripe_subscription = event.data.object
      
      # Find the subscription in our system
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription
      
      # Mark as canceled in our system
      subscription.update(status: 'canceled')
    end
  end
end 