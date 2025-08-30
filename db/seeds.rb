# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
Plan.find_or_create_by!(code: "priv_starter_once") do |p|
  p.name = "Private Starter (3 months)"
  p.kind = "one_time"
  p.amount_cents = 1000
  p.currency = "gbp"
  p.duration_months = 3
  p.gives_premium = false
end

Plan.find_or_create_by!(code: "priv_plus_once") do |p|
  p.name = "Private Plus (one-off)"
  p.kind = "one_time"
  p.amount_cents = 2500
  p.currency = "gbp"
  p.premium_weeks = 2
  p.gives_premium = true
end

Plan.find_or_create_by!(code: "agent_basic_month") do |p|
  p.name = "Agent Basic (20 listings)"
  p.kind = "subscription"
  p.amount_cents = 2900
  p.currency = "gbp"
  p.interval = "month"
end

Plan.find_or_create_by!(code: "agent_unlimited_month") do |p|
  p.name = "Agent Unlimited"
  p.kind = "subscription"
  p.amount_cents = 4900
  p.currency = "gbp"
  p.interval = "month"
  p.premium_weeks = 1
  p.gives_premium = true
end