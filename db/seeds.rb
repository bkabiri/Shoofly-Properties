# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
# db/seeds.rb

require "faker"

puts "Seeding users..."

30.times do
  User.create!(
    email: Faker::Internet.unique.email,
    password: "password123",   # common test password
    full_name: Faker::Name.name,
    mobile_phone: Faker::PhoneNumber.cell_phone_in_e164
  )
end

puts "✅ Seeded 30 buyer users."