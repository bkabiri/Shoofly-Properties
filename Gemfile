source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

gem "rails", "~> 7.0.3"
gem "sprockets-rails"

# Use PostgreSQL for Active Record
gem "pg", "~> 1.5"

# Web server
gem "puma", "~> 5.0"
gem "image_processing", "~> 1.12"
# JS & Hotwire
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "geocoder"
# JSON builders
gem "jbuilder"

# Redis (if you actually use it)
gem "redis", "~> 4.8"

gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "bootsnap", require: false
gem "stripe"
gem "dotenv-rails", groups: [:development, :test] # if you want
# UI
gem "bootstrap", "~> 5.1.3"
gem "kaminari"
# Auth
gem "kaminari-bootstrap"
gem "devise"
gem "sidekiq"
# optional, for scheduled jobs via cron-like syntax
gem "sidekiq-cron", require: false
group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "faker"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end