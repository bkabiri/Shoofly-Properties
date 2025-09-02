# app/controllers/seller/dashboards_controller.rb
module Seller
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    # ❌ remove the hard role gate
    # before_action :ensure_seller!

    def show
      # OPTIONAL: auto-promote to :seller when a signed-in user lands here.
      # Comment out if you don’t want to change roles automatically.
      if defined?(User) && User.respond_to?(:roles) && User.roles.key?("seller")
        current_user.update_column(:role, User.roles["seller"]) unless current_user.seller?
      end

      # Example KPIs / placeholders (replace with real queries)
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

      # If you want to show a banner for users without an approved listing:
      @has_approved_listing =
        begin
          if current_user.respond_to?(:listings)
            current_user.listings.where(status: %w[published approved active]).exists?
          else
            false
          end
        rescue
          false
        end
    end

    private

    # keep the old method around if you ever need a hard lock again
    def ensure_seller!
      return if current_user.seller?
      redirect_to root_path, alert: "Seller access only."
    end
  end
end