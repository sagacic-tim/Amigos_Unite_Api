# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ── Host / URL (used by mailers, routes, etc.) ──
  # Recommended for an API: set APP_HOST to api.amigosunite.org (or similar) in production.
  host     = ENV.fetch("APP_HOST", "amigosunite.org")
  protocol = ENV.fetch("APP_PROTOCOL", "https")
  port_env = ENV["APP_PORT"]
  port     = port_env.present? ? port_env.to_i : nil

  # ── Code loading / caching ──
  config.cache_classes = true
  config.eager_load    = true

  config.consider_all_requests_local = false
  config.require_master_key          = true

  # ── Static files / storage ──
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.active_storage.service     = :local

  # ── SSL (TLS is terminated by host Nginx; ensure it sets X-Forwarded-Proto https) ──
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  # ── Logging ──
  config.log_level = :info
  config.log_tags  = [:request_id]
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # ── Active Job / Sidekiq ──
  config.active_job.queue_adapter = :sidekiq

  # ── URL defaults ──
  config.action_mailer.default_url_options = { host:, protocol:, port: }
  Rails.application.routes.default_url_options = { host:, protocol:, port: }

  # ── Cookies (SPA on another domain) ──
  config.action_dispatch.cookies_same_site_protection = :none

  # ── I18n / deprecations / schema ──
  config.i18n.fallbacks                         = true
  config.active_support.report_deprecations     = false
  config.active_record.dump_schema_after_migration = false

  # ── Action Mailer (SendGrid is OPTIONAL) ──
  # We keep the delivery_method definition, but we disable deliveries unless the key is present.
  sendgrid_key_present = ENV["SENDGRID_API_KEY"].present?

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp

  # If SendGrid is not configured, do not attempt to send mail in production.
  config.action_mailer.perform_deliveries   = sendgrid_key_present

  # If mail is disabled, do not raise. If enabled, you may choose to raise by setting:
  #   MAIL_RAISE_DELIVERY_ERRORS=true
  config.action_mailer.raise_delivery_errors =
    sendgrid_key_present && ENV.fetch("MAIL_RAISE_DELIVERY_ERRORS", "false") == "true"

  unless sendgrid_key_present
    Rails.logger.warn("[mail] SENDGRID_API_KEY missing; email delivery disabled")
  end
end
