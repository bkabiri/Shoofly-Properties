# config/environments/development.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Reload code on change (slower but fine for dev)
  config.cache_classes = false
  config.eager_load = false

  # Show detailed error pages
  config.consider_all_requests_local = true

  # Enable server timing in browser DevTools
  config.server_timing = true

  # ======== Active Storage (local or MinIO S3) ========
  # Default local disk
  config.active_storage.service = :local
  # To test S3/MinIO locally, set in .env:
  # ACTIVE_STORAGE_SERVICE=s3
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # ======== Action Cable ========
  config.action_cable.url = ENV.fetch("ACTION_CABLE_URL", "ws://app.localhost/cable")
  config.action_cable.allowed_request_origins = [
    "http://app.localhost",
    "http://localhost",
    "http://127.0.0.1",
    /http:\/\/localhost:\d+/,
    /http:\/\/127\.0\.0\.1:\d+/
  ]
  config.action_cable.cable = {
    adapter: "redis",
    url: ENV.fetch("REDIS_URL", "redis://redis-snoofly:6379/1")
  }

  # ======== Caching ========
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://redis-snoofly:6379/1") }
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # ======== Action Mailer (SendGrid for dev) ========
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "app.localhost"),
    protocol: ENV.fetch("APP_PROTOCOL", "http")
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: "apikey",                                # literal string per SendGrid docs
    password:  ENV.fetch("SENDGRID_API_KEY", nil),
    domain:    ENV.fetch("APP_HOST", "app.localhost"),
    address:   "smtp.sendgrid.net",
    port:      587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # ======== Logging & misc ========
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.assets.quiet = true

  # Disable Rack::ETag (keeps dev responses clean)
  config.middleware.delete Rack::ETag
end