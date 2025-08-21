# app/controllers/seller/dashboards_controller.rb
module Seller
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_seller!

    def show
      # TODO: replace with real queries
      @stats = {
        active_listings: 0,
        unread_messages: 0,
        upcoming_viewings: 0,
        this_month_views: 0
      }
      @billing_overview = {
        plan: "Free (trial)",
        next_invoice_on: nil,
        amount: "£0.00"
      }
    end

    private

    def ensure_seller!
      return if current_user.seller?
      redirect_to root_path, alert: "Seller access only."
    end
  end
end