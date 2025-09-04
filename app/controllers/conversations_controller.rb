# app/controllers/conversations_controller.rb
class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: :show

  def create
    listing = Listing.find(params[:listing_id])
    seller  = listing.user
    buyer   = current_user

    # Prevent a seller from opening a chat with self
    if seller == buyer
      return redirect_to dashboard_path(tab: "buying"),
                         alert: "You cannot message yourself."
    end

    # Find or start a conversation tied to this listing/buyer/seller
    convo = Conversation.find_or_create_by!(listing: listing, buyer: buyer, seller: seller)

    # Prefer caller's redirect_to, else go to Dashboard > Buying > #messages
    redirect_target = params[:redirect_to].presence ||
                      dashboard_path(tab: "buying", anchor: "messages")

    redirect_to add_query(redirect_target, conversation_id: convo.id),
                notice: "Conversation started."
  end

  def show
    unless @conversation.participant?(current_user)
      return redirect_to dashboard_path(tab: "buying"),
                         alert: "You are not part of that conversation."
    end

    # Always render the inline thread on the dashboard
    redirect_to dashboard_path(tab: "buying",
                               conversation_id: @conversation.id,
                               anchor: "messages")
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  # Safely append / merge query params to any URL (keeps existing query + #anchor)
  def add_query(url, new_params = {})
    uri = URI.parse(url)

    # If it’s a relative path like "/dashboard#messages", give it a base so parsing is robust
    unless uri.host
      base = URI.parse(request.base_url)
      uri  = URI.parse(base.merge(url).to_s)
    end

    existing = Rack::Utils.parse_nested_query(uri.query)
    uri.query = existing.merge(new_params.stringify_keys).to_query.presence
    uri.to_s
  rescue URI::InvalidURIError
    # Fallback—simple concat
    joiner = url.include?("?") ? "&" : "?"
    "#{url}#{joiner}#{new_params.to_query}"
  end
end