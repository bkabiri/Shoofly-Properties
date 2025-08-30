class Plan < ApplicationRecord
  # Suggested enum (optional)
  # enum kind: { one_time: "one_time", subscription: "subscription" }, _suffix: true

  # If you have these columns: code, name, kind, amount_cents, currency,
  # interval (e.g., "month"), yearly_amount_cents (nullable),
  # duration_months (for one-time access windows), premium_weeks, gives_premium

  validates :code, :name, :kind, :amount_cents, :currency, presence: true
  validates :kind, inclusion: { in: %w[one_time subscription] }

  # Convenience
  def one_time?
    kind == "one_time"
  end

  def subscription?
    kind == "subscription"
  end

  # Returns cents for the chosen period
  # period can be: "one_time", "monthly", "yearly"
  def amount_for(period)
    if one_time?
      amount_cents
    else
      case period
      when "yearly"
        # Prefer explicit DB value; otherwise 20% discount from 12 * monthly
        if respond_to?(:yearly_amount_cents) && yearly_amount_cents.present?
          yearly_amount_cents
        else
          ((amount_cents * 12) * 0.80).round # 20% off
        end
      else # monthly (default)
        amount_cents
      end
    end
  end

  # Stripe recurring hash if subscription
  def recurring_for(period)
    return nil unless subscription?
    { interval: (period == "yearly" ? "year" : (interval.presence || "month")) }
  end

  # Human display for line item (you can customize)
  def display_name(period)
    if one_time?
      name
    else
      suffix = (period == "yearly" ? " – yearly" : " – monthly")
      "#{name}#{suffix}"
    end
  end
end