class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_active_subscription, only: [:index, :new]
  
  def index
    @plans = Plan.visible.order(amount: :asc)
  end

  def new
    @plan = Plan.find(params[:plan_id])
    
    if @plan.nil?
      redirect_to subscriptions_index_path, alert: "Plan not found"
      return
    end
    
    # Redirect if already subscribed to this plan
    if @active_subscription.present? && @active_subscription.plan_name == @plan.name
      redirect_to subscriptions_index_path, notice: "You are already subscribed to this plan"
      return
    end
    
    # Create checkout session
    success_url = subscriptions_success_url
    cancel_url = subscriptions_index_url
    
    @checkout_session = StripeService.create_checkout_session(
      plan_id: @plan.stripe_price_id,
      customer_email: current_user.organization.billing_email || current_user.email,
      success_url: success_url,
      cancel_url: cancel_url,
      organization: current_user.organization
    )
  end

  def checkout
    @plan = Plan.find(params[:plan_id])
    
    if @plan.nil?
      redirect_to subscriptions_index_path, alert: "Plan not found"
      return
    end
    
    begin
      @session = StripeService.create_checkout_session(current_organization, @plan)
      
      # For API response
      respond_to do |format|
        format.html
        format.json { render json: { checkout_url: @session.url } }
      end
    rescue => e
      redirect_to subscriptions_index_path, alert: "Failed to create checkout session: #{e.message}"
    end
  end

  def success
    # Handle the successful return from Stripe Checkout
    session_id = params[:session_id]
    
    if session_id.present?
      # Verify the checkout session
      session = Stripe::Checkout::Session.retrieve(session_id)
      
      if session.payment_status == 'paid'
        # Find or create the subscription
        @subscription = current_user.organization.subscription || 
                        current_user.organization.build_subscription
        
        # Update subscription details from session
        @subscription.status = 'active'
        @subscription.stripe_subscription_id = session.subscription
        @subscription.plan_name = Plan.find_by(stripe_price_id: session.line_items.data[0].price.id)&.name
        @subscription.save
        
        # Send confirmation email
        SubscriptionMailer.subscription_confirmation(current_user.organization).deliver_later
        
        flash[:notice] = "Thank you for subscribing to FanPilot!"
      else
        flash[:alert] = "Payment was not successful. Please try again."
        redirect_to subscriptions_index_path
      end
    else
      # If no session ID, just find the active subscription
      @subscription = current_user.organization.subscription
      if @subscription.nil?
        flash[:alert] = "Subscription not found. Please try again."
        redirect_to subscriptions_index_path
      end
    end
  end
  
  def cancel
    subscription = current_user.organization.subscription
    
    if subscription&.can_cancel?
      # Cancel at Stripe
      if subscription.stripe_subscription_id.present?
        begin
          Stripe::Subscription.update(
            subscription.stripe_subscription_id,
            { cancel_at_period_end: true }
          )
          
          subscription.update(status: 'canceled')
          @subscription = subscription
          
          flash.now[:notice] = "Your subscription has been cancelled and will end on #{subscription.current_period_end&.strftime('%B %d, %Y')}."
          render :cancel_confirmation
        rescue Stripe::StripeError => e
          flash[:alert] = "Failed to cancel subscription: #{e.message}"
          redirect_to subscriptions_index_path
        end
      else
        # Just cancel locally if no Stripe ID (for free plans)
        subscription.update(status: 'canceled')
        @subscription = subscription
        
        flash.now[:notice] = "Your subscription has been cancelled."
        render :cancel_confirmation
      end
    else
      flash[:alert] = "Unable to cancel subscription. Please contact support."
      redirect_to subscriptions_index_path
    end
  end
  
  private
  
  def require_organization
    unless current_user.organization.present?
      flash[:alert] = "You need to belong to an organization to manage subscriptions."
      redirect_to dashboard_index_path
    end
  end
  
  def current_organization
    current_user.organization
  end
  
  def set_active_subscription
    @active_subscription = current_user.organization.subscription
  end
end
