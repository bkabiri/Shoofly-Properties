# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot.
  config.eager_load = true
  config.require_master_key = false
  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # ======== Action Cable (Redis) ========
  # Public WS/WSS endpoint your clients connect to (Nginx/ALB should proxy /cable to app).
  # e.g. ACTION_CABLE_URL=wss://app.snoofly.com/cable
  config.action_cable.url = ENV["ACTION_CABLE_URL"]

  # Lock down allowed origins (adjust the regex/domains as needed).
  config.action_cable.allowed_request_origins = [
    %r{\Ahttps?://(www\.)?snoofly\.co.uk\z},
    ENV["APP_HOST"].present? ? %r{\Ahttps?://(www\.)?#{Regexp.escape(ENV["APP_HOST"])}\z} : nil
  ].compact
  # =====================================

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key.
  # config.require_master_key = true

  # Static files (handled by your web server unless overridden)
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Assets
  # config.assets.css_compressor = :sass
  config.assets.compile = false
  # config.asset_host = ENV["ASSET_HOST"] if ENV["ASSET_HOST"].present?

  # Files
  config.active_storage.service = :local
  # (Switch to :amazon / :google / :azure in production when ready)

  # SSL (enable when you terminate TLS in front or on the app)
  # config.force_ssl = true
  config.log_level = :info
  config.log_tags  = [:request_id]

  # ======== Redis cache store ========
  # e.g. REDIS_URL=redis://:password@redis-host:6379/1
  if ENV["REDIS_URL"].present?
    config.cache_store = :redis_cache_store, {
      url: ENV["REDIS_URL"],
      # Optional niceties:
      reconnect_attempts: 1,
      error_handler: ->(method:, returning:, exception:) {
        Rails.logger.warn("Redis cache error: #{method} -> #{exception.class}: #{exception.message}")
      }
    }
  end
  # ===================================

  # Active Job (Turbo Streams jobs will use this)
  # Use a real backend (Sidekiq/Resque) when you’re ready; leaving :async is fine to start.
  # config.active_job.queue_adapter     = :sidekiq
  # config.active_job.queue_name_prefix = "snoofly_production"

  # ======== Action Mailer (SendGrid) ========
  # Host used in links (Devise, etc.)
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "app.snoofly.co.uk"),
    protocol: "https"
  }
  config.action_mailer.asset_host = "https://#{ENV.fetch("APP_HOST", "app.snoofly.co.uk")}"

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: "apikey",                             # literal per SendGrid
    password:  ENV.fetch("SENDGRID_API_KEY"),        # required
    domain:    ENV.fetch("APP_HOST", "app.snoofly.com"),
    address:   "smtp.sendgrid.net",
    port:      587,
    authentication: :plain,
    enable_starttls_auto: true
  }
  # ============================================

  # I18n fallbacks
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # Logging
  config.log_formatter = ::Logger::Formatter.new
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end