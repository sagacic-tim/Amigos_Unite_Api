# config/environments/production.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # -----------------------------------------------
  # Code Loading and Caching
  # -----------------------------------------------
  config.cache_classes = true
  config.eager_load = true

  # -----------------------------------------------
  # Error Reporting
  # -----------------------------------------------
  config.consider_all_requests_local = false

  # -----------------------------------------------
  # Credentials and Secrets
  # -----------------------------------------------
  config.require_master_key = true  # Required to decrypt credentials

  # -----------------------------------------------
  # Static Files
  # -----------------------------------------------
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # -----------------------------------------------
  # Asset Host (optional, for CDN/static server)
  # config.asset_host = "http://assets.example.com"

  # -----------------------------------------------
  # File Dispatch Headers (Apache/NGINX)
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"        # Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"  # NGINX

  # -----------------------------------------------
  # Active Storage (local only — S3 or GCS will come later)
  # -----------------------------------------------
  config.active_storage.service = :local

  # -----------------------------------------------
  # Action Cable (optional for WebSockets)
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # -----------------------------------------------
  # Security: Force SSL and secure cookies
  # -----------------------------------------------
  config.force_ssl = true

  # -----------------------------------------------
  # Logging
  # -----------------------------------------------
  config.log_level = :info
  config.log_tags = [ :request_id ]

  # Optional: Custom logger
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.log_formatter = ::Logger::Formatter.new

  # -----------------------------------------------
  # Active Job
  # -----------------------------------------------
  # Future config:
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "amigos_unite_api_production"

  # -----------------------------------------------
  # Caching (optional; configure Redis or Memcached first)
  # config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }

  # -----------------------------------------------
  # Action Mailer (no SMTP yet, but delivery errors should be reported)
  # -----------------------------------------------
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching      = false
  config.action_mailer.delivery_method      = :smtp
  config.action_mailer.perform_deliveries   = true
  config.action_mailer.default_url_options  = { host: "amigosunite.org", protocol: "https" }

  config.active_job.queue_adapter = :sidekiq

  # For URL helpers used outside controllers/mailers (e.g., jobs/services)
  Rails.application.routes.default_url_options = { host: "amigosunite.org", protocol: "https" }

  # -----------------------------------------------
  # I18n
  # -----------------------------------------------
  config.i18n.fallbacks = true

  # -----------------------------------------------
  # Deprecation and Schema Dump
  # -----------------------------------------------
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
