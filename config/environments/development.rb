require "active_support/core_ext/integer/time"

Rails.application.configure do
  # -----------------------------------------------
  # URL and SSL Settings (Important for OAuth testing)
  # -----------------------------------------------
  host = 'localhost'
  port = 3001

  config.force_ssl = true # Required for OAuth callbacks and secure cookies
  config.action_mailer.default_url_options = { host:, port: }
  config.action_mailer.perform_caching = false
  Rails.application.routes.default_url_options = { host:, port: }
  config.default_url_options = { host: "http://#{host}:#{port}" }

  # -----------------------------------------------
  # Active Storage
  # -----------------------------------------------
  config.active_storage.service = :local

  # -----------------------------------------------
  # Code Loading & Caching
  # -----------------------------------------------
  config.cache_classes = false
  config.eager_load = false

  # -----------------------------------------------
  # Error Handling & Logging
  # -----------------------------------------------
  config.consider_all_requests_local = true
  config.server_timing = true
  config.log_level = :debug
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Optional: Log format for cleaner logs
  config.log_formatter = ::Logger::Formatter.new

  # -----------------------------------------------
  # Caching Configuration
  # -----------------------------------------------
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # -----------------------------------------------
  # Action Mailer Delivery Settings
  # -----------------------------------------------
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true
  # To use letter_opener for viewing emails in the browser:
  # config.action_mailer.delivery_method = :letter_opener
  # config.action_mailer.perform_deliveries = true

  # -----------------------------------------------
  # Optional: Raise on missing translations
  # config.i18n.raise_on_missing_translations = true

  # -----------------------------------------------
  # Optional: Annotate views with file names
  # config.action_view.annotate_rendered_view_with_filenames = true

  # -----------------------------------------------
  # Optional: Allow Action Cable from any origin (if needed)
  # config.action_cable.disable_request_forgery_protection = true
end
