class CheckoutSessionsController < ApplicationController
  before_action :authenticate_user!

  # POST /checkout_sessions
  # payload: { plan_code: "priv_starter_once", listing_id: "123" }
  def create
    plan = Plan.find_by!(code: params[:plan_code])
    listing = current_user.listings.find_by(id: params[:listing_id]) # optional, can be nil

    # SECURE: never trust client-sent amounts — always use plan values
    line_item = {
      quantity: 1,
      price_data: {
        currency: plan.currency,
        unit_amount: plan.amount_cents,
        product_data: {
          name: plan.name,
          description: plan.one_time? && plan.duration_months ? "#{plan.duration_months} months access" : nil
        }
      }
    }

    session_params = {
      mode: (plan.subscription? ? "subscription" : "payment"),
      payment_method_types: ["card"],
      success_url: success_url_with_placeholder, # You can make a dedicated success route
      cancel_url: cancel_url,
      client_reference_id: "user:#{current_user.id}|plan:#{plan.id}|listing:#{listing&.id}",
      metadata: {
        user_id: current_user.id,
        plan_id: plan.id,
        listing_id: listing&.id
      },
      line_items: [line_item]
    }

    if plan.subscription?
      session_params[:line_items][0][:price_data][:recurring] = { interval: plan.interval }
    end

    session = Stripe::Checkout::Session.create(session_params)

    Payment.create!(
      user: current_user,
      plan: plan,
      listing: listing,
      stripe_session_id: session.id,
      amount_cents: plan.amount_cents,
      currency: plan.currency,
      status: "pending"
    )

    render json: { id: session.id, publishableKey: StripeConfig::PUBLISHABLE_KEY }
  end

  private

  def success_url_with_placeholder
    # users see this after payment; {CHECKOUT_SESSION_ID} will be replaced by Stripe
    url_for(controller: "payments", action: "success", only_path: false) + "?sid={CHECKOUT_SESSION_ID}"
  end

  def cancel_url
    # back to pricing or listing edit
    pricing_url # or listings_url
  end
end