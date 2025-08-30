# app/controllers/checkout_controller.rb
class CheckoutController < ApplicationController
  protect_from_forgery except: :sessions

  def sessions
    plan_code = params[:plan_code].to_s.presence
    period    = normalize_period(params[:period].to_s) # "one_time"|"monthly"|"yearly"
    plan      = Plan.find_by!(code: plan_code)
    currency  = plan.currency || "gbp"

    product_data = {
      name:        plan.display_name(period),
      description: plan.short_description_or_fallback
    }

    if (img = asset_url_if_exists(plan.image_asset_or_fallback))
      product_data[:images] = [img]
    end

    line_item =
      if plan.one_time?
        {
          price_data: {
            currency:    currency,
            product_data: product_data,
            unit_amount: plan.amount_for("one_time")
          },
          quantity: 1
        }
      else
        {
          price_data: {
            currency:    currency,
            product_data: product_data,
            unit_amount: plan.amount_for(period),
            recurring:   plan.recurring_for(period) # { interval: "month" | "year" }
          },
          quantity: 1
        }
      end

    mode        = plan.one_time? ? "payment" : "subscription"
    success_url = ENV.fetch("STRIPE_SUCCESS_URL")
    cancel_url  = ENV.fetch("STRIPE_CANCEL_URL")

    session = Stripe::Checkout::Session.create(
      mode:        mode,
      line_items:  [line_item],
      success_url: success_url,
      cancel_url:  cancel_url,
      metadata:    { plan_code: plan.code, period: period }
    )

    render json: { url: session.url }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unknown plan" }, status: :unprocessable_entity
  rescue KeyError => e
    render json: { error: "Missing ENV: #{e.message}" }, status: :unprocessable_entity
  rescue Stripe::StripeError => e
    Rails.logger.error("[Stripe] #{e.class}: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def normalize_period(p)
    case p
    when "yearly", "annual", "annually" then "yearly"
    when "one_time", "once"             then "one_time"
    else "monthly"
    end
  end

  # Return a compiled asset URL if present; otherwise nil
  def asset_url_if_exists(name)
    return nil if name.blank?
    helpers.asset_url(name)
  rescue Sprockets::Rails::Helper::AssetNotFound
    nil
  end
end