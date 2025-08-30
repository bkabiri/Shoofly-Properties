class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = request.body.read
    sig = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = StripeConfig::WEBHOOK_SECRET

    event = Stripe::Webhook.construct_event(payload, sig, endpoint_secret)

    case event["type"]
    when "checkout.session.completed"
      handle_checkout_session_completed(event["data"]["object"])
    when "invoice.paid"
      # renewals for subscriptions
      # You can keep access active, credit agents, etc.
    when "customer.subscription.deleted"
      # downgrade if you need to
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.error("Stripe webhook error: #{e.message}")
    head :bad_request
  end

  private

  def handle_checkout_session_completed(session)
    payment_intent_id = session["payment_intent"]
    subscription_id   = session["subscription"]
    metadata          = session["metadata"] || {}
    session_id        = session["id"]

    payment = Payment.find_by!(stripe_session_id: session_id)
    payment.update!(
      status: "paid",
      stripe_payment_intent_id: payment_intent_id,
      stripe_subscription_id: subscription_id,
      stripe_payload: session
    )

    plan    = payment.plan
    listing = payment.listing

    # Grant access/publish
    if plan.one_time?
      if listing
        listing.update!(
          published_at: Time.current,
          access_expires_at: plan.duration_months ? Time.current + plan.duration_months.months : nil,
          premium_until: plan.gives_premium && plan.premium_weeks ? Time.current + plan.premium_weeks.weeks : nil
        )
      end
      # Notify investors if needed (background job)
    else
      # Subscriptions: flag the user/account as active
      # For agents you might update an account plan row, limits, etc.
      if listing
        listing.update!(
          published_at: Time.current,
          premium_until: plan.gives_premium && plan.premium_weeks ? Time.current + plan.premium_weeks.weeks : nil
        )
      end
    end
  end
end