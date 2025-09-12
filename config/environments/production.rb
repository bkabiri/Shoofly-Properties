# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Host authorization (for multiple domains if needed)
  if ENV["ALLOWED_HOSTS"].present?
    config.hosts += ENV["ALLOWED_HOSTS"].split(",").map(&:strip)
  end

  # === Core Rails settings ===
  config.cache_classes = true
  config.eager_load    = true

  # Fail fast if master key is missing/wrong
  config.require_master_key = true
  config.secret_key_base    = ENV.fetch("SECRET_KEY_BASE")

  # Error pages & caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # === Active Storage (MinIO) ===
  config.active_storage.service = :minio

  # === Action Cable ===
  config.action_cable.url = ENV["ACTION_CABLE_URL"]
  config.action_cable.allowed_request_origins = [
    %r{\Ahttps?://(www\.)?snoofly\.co\.uk\z},
    (ENV["APP_HOST"].present? ? %r{\Ahttps?://(www\.)?#{Regexp.escape(ENV["APP_HOST"])}\z} : nil)
  ].compact

  # === Static files & assets ===
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile             = false
  # config.asset_host = ENV["ASSET_HOST"] if ENV["ASSET_HOST"].present?

  # === Logging ===
  config.log_level = :info
  config.log_tags  = [:request_id]

  config.log_formatter = ::Logger::Formatter.new
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # === Redis cache store (optional) ===
  if ENV["REDIS_URL"].present?
    config.cache_store = :redis_cache_store, {
      url: ENV["REDIS_URL"],
      reconnect_attempts: 1,
      error_handler: ->(method:, returning:, exception:) {
        Rails.logger.warn("Redis cache error: #{method} -> #{exception.class}: #{exception.message}")
      }
    }
  end

  # === Action Mailer (SendGrid) ===
  config.action_mailer.default_url_options = {
    host:     ENV.fetch("APP_HOST", "snoofly.co.uk"),
    protocol: "https"
  }
  config.action_mailer.asset_host          = "https://#{ENV.fetch("APP_HOST", "snoofly.co.uk")}"

  config.action_mailer.perform_caching       = false
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings   = {
    user_name: "apikey", # literal string
    password:  ENV.fetch("SENDGRID_API_KEY") { raise "Missing SENDGRID_API_KEY" },
    domain:    ENV.fetch("APP_HOST", "snoofly.co.uk"),
    address:   "smtp.sendgrid.net",
    port:      587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # === I18n & Deprecations ===
  config.i18n.fallbacks              = true
  config.active_support.report_deprecations = false

  # === Active Record ===
  config.active_record.dump_schema_after_migration = false
end