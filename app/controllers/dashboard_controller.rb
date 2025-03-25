class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    if current_user.agency_user?
      agency_dashboard
    elsif current_user.creator?
      creator_dashboard
    else
      # Regular user
      render :index
    end
  end
  
  private

  def agency_dashboard
    # Fetch data needed for agency dashboard
    @organizations = current_user.organizations
    @agency_stats = {
      total_creators: CreatorProfile.joins(:organization).where(organization_id: @organizations.pluck(:id)).count,
      active_creators: CreatorProfile.joins(:organization).where(organization_id: @organizations.pluck(:id), status: 'active').count,
      total_revenue: "$9,842", # This would be calculated from real data
      growth_rate: "18.5%" # This would be calculated from real data
    }
    render :agency_dashboard
  end
  
  def creator_dashboard
    # Fetch data needed for creator dashboard
    @creator_profile = current_user.creator_profile
    render :creator_dashboard
  end
end
