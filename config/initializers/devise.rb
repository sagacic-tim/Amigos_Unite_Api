Devise.setup do |config|
  config.mailer_sender = 'tmichel@ssgacicweb.com'
  config.mailer = 'Devise::Mailer'
  config.parent_mailer = 'ActionMailer::Base'

  require 'devise/orm/active_record'

  config.authentication_keys = [:login_attribute]
  config.case_insensitive_keys = [:login_attribute]
  config.strip_whitespace_keys = [:login_attribute]

  config.skip_session_storage = [:http_auth, :token_auth]

  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = Rails.application.credentials.dig(:devise_pepper)

  config.reconfirmable = true
  config.password_length = 10..64
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.timeout_in = 12.hours

  config.navigational_formats = ['*/*', :html, :json]
  config.scoped_views = true
  config.sign_out_via = :delete

  # Optional (recommended in production)
  config.send_email_changed_notification = true
  config.send_password_change_notification = true

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.dig(:devise_jwt_secret_key)
    jwt.dispatch_requests = [['POST', %r{^/api/v1/login$}]]
    jwt.revocation_requests = [['DELETE', %r{^/api/v1/logout$}]]
    jwt.expiration_time = 2.hours.to_i
    jwt.request_formats = { api: [:json] }
  end

  config.warden do |manager|
    manager.failure_app = CustomFailureApp
  end
end
