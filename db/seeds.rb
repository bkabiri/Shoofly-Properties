# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
Plan.find_or_create_by!(code: "priv_starter_once") do |p|
  p.name = "Starter (3 Months)"
  p.kind = "one_time"
  p.amount_cents = 1000
  p.currency = "gbp"
  p.duration_months = 3
  p.short_description = "Full access for 3 months"
  p.features = [
    "Full access to Snoofly for 3 months",
    "1 active property listing",
    "Unlimited photos & detailed description",
    "Viewing scheduling calendar",
    "Support + partner services access"
  ]
  p.image_asset = "starter.png"
  p.submit_note = "You’re paying Snoofly for Starter (3 Months)."
end

Plan.find_or_create_by!(code: "priv_plus_once") do |p|
  p.name = "Private Plus (one-off)"
  p.kind = "one_time"
  p.amount_cents = 2500
  p.currency = "gbp"
  p.short_description = "Premium placement, investor reach, priority support"
  p.features = [
    "Full access, up to 2 active listings",
    "Premium placement for 2 weeks",
    "Investors notified",
    "Priority support",
    "Basic analytics dashboard"
  ]
  p.image_asset = "plus.png"
  p.submit_note = "You’re paying Snoofly for Private Plus."
end