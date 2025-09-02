# app/controllers/admin/dashboards_controller.rb
module Admin
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def show
      @kpis = {
        active_listings: Listing.where(status: %w[approved published active]).count,
        private_sellers: User.where(role: :seller).count,
        estate_agents:   User.where(role: :estate_agent).count,
        open_tickets:    Ticket.where(status: :open).count,
        tickets_sla_breach: Ticket.where(status: :open).where("updated_at < ?", 48.hours.ago).count
      }

      @private_sellers = User.where(role: :seller).order(created_at: :desc).limit(50)
      @estate_agents   = User.where(role: :estate_agent).order(created_at: :desc).limit(50)

      @pending_listings = Listing.where(status: :pending).order(created_at: :asc).limit(100)
      @agent_requests   = User.where(role: :seller, requested_estate_agent: true).order(updated_at: :asc).limit(100)

      @properties = Listing.order(updated_at: :desc).limit(100)

      @tickets = Ticket.order(updated_at: :desc).limit(100)
    end

    private

    def require_admin!
      redirect_to(root_path, alert: "Admins only.") unless current_user&.admin?
    end
  end
end