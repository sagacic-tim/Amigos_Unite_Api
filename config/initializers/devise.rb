# config/initializers/devise.rb #

Devise.setup do |config|
  config.mailer_sender = 'tmichel@ssgacicweb.com'
  config.mailer = 'Devise::Mailer'
  config.parent_mailer = 'ActionMailer::Base'

  require 'devise/orm/active_record'

  config.authentication_keys   = [:login_attribute]
  config.case_insensitive_keys = [:login_attribute]
  config.strip_whitespace_keys = [:login_attribute]

  config.skip_session_storage = [:http_auth, :token_auth]

  config.stretches = Rails.env.test? ? 1 : 12 

  config.reconfirmable = true
  config.password_length = 10..64
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.timeout_in = 2.hours

  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :time
  config.maximum_attempts = 5
  config.unlock_in = 15.minutes

  config.navigational_formats = ['*/*', :html, :json]
  config.scoped_views = true
  config.sign_out_via = :delete

  # Optional (recommended in production)
  config.send_email_changed_notification = true
  config.send_password_change_notification = true

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.dig(:devise, :jwt_secret_key)
    jwt.dispatch_requests = [['POST', %r{^/api/v1/login$}]]
    jwt.revocation_requests = [['DELETE', %r{^/api/v1/logout$}]]
    jwt.expiration_time = 2.hours.to_i
    jwt.request_formats = { amigo: [:json] }
  end

  config.pepper = Rails.application.credentials.dig(:devise, :pepper)

  config.warden do |manager|
    manager.failure_app = CustomFailureApp
  end
end
