class StripeWebhookController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_stripe_webhook_secret
  
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, @stripe_webhook_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid payload: #{e.message}"
      return render json: { error: 'Invalid payload' }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: #{e.message}"
      return render json: { error: 'Invalid signature' }, status: :bad_request
    end
    
    # Handle the event
    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event)
    when 'customer.subscription.updated'
      handle_subscription_updated(event)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event)
    when 'invoice.payment_failed'
      handle_payment_failed(event)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end
    
    render json: { received: true }
  end
  
  private
  
  def set_stripe_webhook_secret
    @stripe_webhook_secret = Rails.application.credentials.stripe[:webhook_secret]
  end
  
  def handle_checkout_session_completed(event)
    StripeService.handle_checkout_completed(event)
  end
  
  def handle_subscription_updated(event)
    StripeService.handle_subscription_updated(event)
  end
  
  def handle_subscription_deleted(event)
    StripeService.handle_subscription_deleted(event)
  end
  
  def handle_payment_failed(event)
    invoice = event.data.object
    
    # Find the subscription in our system
    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription
    
    organization = subscription.organization
    return unless organization
    
    # Update subscription status
    subscription.update(status: 'past_due')
    
    # Notify the organization of payment failure
    SubscriptionMailer.payment_failed(organization, invoice).deliver_later
  end
end 