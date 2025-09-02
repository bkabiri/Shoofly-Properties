# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
if User.where(role: "admin").none?
  u = User.find_or_create_by!(email: "admin@snoofly.com") do |x|
    x.password = SecureRandom.base58(16)
    x.role     = "admin"
  end
  puts "Seeded admin: #{u.email}"
end