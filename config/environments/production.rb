# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ── Host / URL (used by mailers, routes, etc.) ──
  host      = ENV.fetch("APP_HOST", "sagacicweb.com")
  protocol  = ENV.fetch("APP_PROTOCOL", "https")
  port_env  = ENV["APP_PORT"]
  port      = port_env.present? ? port_env.to_i : nil

  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false
  config.require_master_key = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.active_storage.service = :local

  config.force_ssl = true

  config.log_level = :info
  config.log_tags  = [:request_id]

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.log_formatter = ::Logger::Formatter.new

  # Active Job
  config.active_job.queue_adapter = :sidekiq

  # Action Mailer
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching      = false
  config.action_mailer.delivery_method      = :smtp
  config.action_mailer.perform_deliveries   = true
  config.action_mailer.default_url_options  = { host:, protocol:, port: }

  Rails.application.routes.default_url_options = { host:, protocol:, port: }

  # If you need cross-site cookies in production (SPA on another domain)
  config.action_dispatch.cookies_same_site_protection = :none

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
