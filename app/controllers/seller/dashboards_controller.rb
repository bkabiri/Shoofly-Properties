# app/controllers/seller/dashboards_controller.rb
module Seller
  class DashboardsController < ApplicationController
    before_action :authenticate_user!

    def show
      # Set a default role ONLY if the user truly has none
      if defined?(User) &&
         User.respond_to?(:roles) &&
         current_user.respond_to?(:no_role?) &&
         current_user.no_role? &&
         User.roles.key?("seller")
        current_user.update_column(:role, User.roles["seller"])
      end

      # -------------------------------
      # Conversations (left sidebar)
      # -------------------------------
      @conversations = Conversation
        .where("buyer_id = :uid OR seller_id = :uid", uid: current_user.id)
        .includes(:listing, :buyer, :seller)
        .order(Arel.sql("COALESCE(last_message_at, updated_at) DESC"))

      # -------------------------------
      # Which conversation should open?
      # Priority:
      #   1) explicit conversation_id
      #   2) deep link: chat_listing_id + chat_with_id (create or reuse)
      # -------------------------------
      @open_conversation = nil

      if params[:conversation_id].present?
        @open_conversation = @conversations.find_by(id: params[:conversation_id])
      elsif params[:chat_listing_id].present? && params[:chat_with_id].present?
        listing = Listing.find_by(id: params[:chat_listing_id])
        other   = User.find_by(id: params[:chat_with_id])
        if listing && other
          @open_conversation = Conversation.find_or_create_by!(
            listing: listing,
            buyer:   current_user,
            seller:  other
          )
          # Ensure it shows up in the sidebar list immediately
          @conversations = (@conversations.to_a | [@open_conversation]).sort_by { |c|
            c.last_message_at || c.updated_at
          }.reverse
        end
      end

      # Messages payload for the open thread
      if @open_conversation&.respond_to?(:participant?) && @open_conversation.participant?(current_user)
        @message  = Message.new
        @messages = @open_conversation.messages.order(:created_at).limit(500)
      else
        @message  = Message.new
        @messages = []
      end

      # -------------------------------
      # KPIs / placeholders (keep as-is)
      # -------------------------------
      @stats = {
        active_listings:   0,
        unread_messages:   0,
        upcoming_viewings: 0,
        this_month_views:  0
      }

      @billing_overview = {
        plan:           "Free (trial)",
        next_invoice_on: nil,
        amount:         "£0.00"
      }

      # Banner: does the user have an approved listing?
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

    # Keep around if you ever want a hard seller-only lock again.
    def ensure_seller!
      return if current_user.respond_to?(:seller?) && current_user.seller?
      redirect_to root_path, alert: "Seller access only."
    end
  end
end