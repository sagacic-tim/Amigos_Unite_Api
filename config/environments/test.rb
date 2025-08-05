# config/environments/test.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # -----------------------------------------------
  # Code Loading & Caching
  # -----------------------------------------------
  config.cache_classes = true
  config.eager_load = ENV["CI"].present?

  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # -----------------------------------------------
  # Error Handling
  # -----------------------------------------------
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = false  # Raise errors instead of rendering templates

  # -----------------------------------------------
  # Forgery Protection
  # -----------------------------------------------
  config.action_controller.allow_forgery_protection = false

  # -----------------------------------------------
  # Active Storage
  # -----------------------------------------------
  config.active_storage.service = :test  # Uses tmp/storage during tests

  # -----------------------------------------------
  # Action Mailer
  # -----------------------------------------------
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  # Emails will be accumulated in ActionMailer::Base.deliveries array

  # -----------------------------------------------
  # Deprecations
  # -----------------------------------------------
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # -----------------------------------------------
  # Internationalization & View Debugging
  # -----------------------------------------------
  # config.i18n.raise_on_missing_translations = true
  # config.action_view.annotate_rendered_view_with_filenames = true
end
