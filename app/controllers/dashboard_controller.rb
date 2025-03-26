class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard'
  
  def index
    # Prioritize creator profile over agency if both exist for the user
    if current_user.creator?
      creator_dashboard
    elsif current_user.agency_owner?
      agency_dashboard
    elsif current_user.agency_member?
      agency_member_dashboard
    else
      # Regular user - should be redirected to create one of these profiles
      redirect_to root_path, notice: "Please complete your registration" 
    end
  end
  
  private

  def agency_dashboard
    # Fetch data needed for agency dashboard
    @organization = current_user.organization
    
    # Calculate basic statistics
    total_creators = CreatorProfile.where(organization_id: @organization.id).count
    active_creators = CreatorProfile.where(organization_id: @organization.id, status: 'active').count
    
    # Calculate revenue (this would use real transaction data in production)
    current_month_revenue = rand(5000..12000)
    last_month_revenue = current_month_revenue * (1 - (rand(-10..25) / 100.0))
    growth_percentage = ((current_month_revenue - last_month_revenue) / last_month_revenue * 100).round(1)
    growth_direction = growth_percentage >= 0 ? "+" : ""
    
    @agency_stats = {
      total_creators: total_creators,
      active_creators: active_creators,
      total_revenue: "$#{number_with_delimiter(current_month_revenue)}",
      growth_rate: "#{growth_direction}#{growth_percentage}%",
      commission: "$#{number_with_delimiter((current_month_revenue * 0.15).round)}"
    }
    
    # Get the top 5 creators by recent activity
    @top_creators = CreatorProfile.where(organization_id: @organization.id)
                                  .order(updated_at: :desc)
                                  .limit(5)
    
    render :agency_dashboard
  end
  
  def agency_member_dashboard
    # For now, just show the same view as agency owners
    # with potential restrictions applied at the view level
    agency_dashboard
  end
  
  def creator_dashboard
    # Fetch data needed for creator dashboard
    @creator_profile = current_user.creator_profile
    
    # Make sure we're not showing agency banners or conflicting elements
    @hide_agency_content = true
    
    render :creator_dashboard
  end
end
