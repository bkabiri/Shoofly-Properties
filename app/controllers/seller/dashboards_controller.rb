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
      # Buyer KPIs (Sellers Contacted / New Messages / Upcoming Viewings)
      # -------------------------------

      # Conversations where the current user is the buyer
      buyer_convos = @conversations.select { |c| c.buyer_id == current_user.id }

      # Sellers Contacted = distinct sellers across buyer's conversations
      @sellers_contacted =
        if buyer_convos.any?
          seller_ids = buyer_convos.map(&:seller_id).compact.uniq
          User.where(id: seller_ids).to_a
        else
          []
        end

      # New / Recent messages
      @recent_messages =
        begin
          # Build a base scope across those conversations
          convo_ids = buyer_convos.map(&:id)
          if convo_ids.empty?
            []
          else
            scope = Message.where(conversation_id: convo_ids)

            if Message.column_names.include?("read_at") && Message.column_names.include?("recipient_id")
              # Prefer unread messages (to the current user)
              scope.where(recipient_id: current_user.id, read_at: nil).to_a
            else
              # Fallback: messages from the other party in the last 7 days
              scope.where.not(user_id: current_user.id)
                   .where("messages.created_at >= ?", 7.days.ago)
                   .to_a
            end
          end
        rescue
          []
        end

      # Upcoming viewings (safe fallback if your app doesn't have Viewing)
      @upcoming_viewings =
        if defined?(Viewing)
          Viewing.where(user_id: current_user.id)
                 .where("scheduled_at >= ?", Time.current)
                 .order(:scheduled_at)
                 .limit(10)
                 .to_a
        else
          []
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

      # Fill unread_messages if we computed a set above
      begin
        @stats[:unread_messages] = @recent_messages.size if @recent_messages.respond_to?(:size)
      rescue
        # keep default
      end

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