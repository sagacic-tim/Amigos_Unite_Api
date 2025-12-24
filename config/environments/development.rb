# config/environments/development.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  host = "localhost"
  port = 3001
  protocol = "https" # since you’re using force_ssl + mkcert locally

  config.force_ssl = true
  config.action_mailer.default_url_options = { host:, protocol:, port: }
  Rails.application.routes.default_url_options = { host:, protocol:, port: }
  config.default_url_options = { host:, protocol:, port: }

  config.active_storage.service = :local

  config.cache_classes = false
  config.eager_load = false

  config.consider_all_requests_local = true
  config.server_timing = true
  config.log_level = :debug
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # SameSite=None for SPA <-> API cookies
  config.action_dispatch.cookies_same_site_protection = :none

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  config.active_job.queue_adapter = :sidekiq

  config.log_formatter = ::Logger::Formatter.new

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true

  config.action_controller.action_on_unpermitted_parameters = :raise
end
