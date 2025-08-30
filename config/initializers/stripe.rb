# app/config/initializers/stripe.rb
Rails.application.reloader.to_prepare do
  Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")

  # Ensure your Price IDs exist in ENV (names from your earlier message)
  %w[
    STRIPE_PRICE_PRIV_STARTER_ONCE
    STRIPE_PRICE_PRIV_PLUS_MONTH
    STRIPE_PRICE_AGENT_BASIC_MONTH
    STRIPE_PRICE_AGENT_UNLIMITED_MONTH
  ].each do |key|
    Rails.logger.warn("[Stripe] Missing ENV #{key}") unless ENV[key].present?
  end
end