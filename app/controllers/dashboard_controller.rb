class DashboardController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  layout 'dashboard'
  
  def index
    # All users have an organization and use the same dashboard
    dashboard
  end
  
  private

  def dashboard
    # Fetch data needed for dashboard
    @organization = current_user.organization
    
    # Calculate basic statistics
    total_creators = @organization.creator_profiles.count
    active_creators = @organization.creator_profiles.where(status: 'active').count
    
    # Calculate revenue (this would use real transaction data in production)
    current_month_revenue = rand(5000..12000)
    last_month_revenue = current_month_revenue * (1 - (rand(-10..25) / 100.0))
    growth_percentage = ((current_month_revenue - last_month_revenue) / last_month_revenue * 100).round(1)
    growth_direction = growth_percentage >= 0 ? "+" : ""
    
    @dashboard_stats = {
      total_creators: total_creators,
      active_creators: active_creators,
      total_revenue: "$#{number_with_delimiter(current_month_revenue)}",
      growth_rate: "#{growth_direction}#{growth_percentage}%",
      commission: "$#{number_with_delimiter((current_month_revenue * 0.15).round)}"
    }
    
    # Get the top 5 creators by recent activity
    @top_creators = @organization.creator_profiles.order(updated_at: :desc).limit(5)
    
    render :dashboard
  end
end
