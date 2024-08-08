# config/initializers/warden.rb

Rails.application.reloader.to_prepare do
  # Ensure the Amigo model is loaded
  require_dependency 'amigo'

  Warden::JWTAuth.configure do |config|
    config.secret = Rails.application.credentials[:devise_jwt_secret_key]
    config.dispatch_requests = [
      ['POST', %r{^/api/v1/login$}],
      ['DELETE', %r{^/api/v1/logout$}]
    ]
    config.revocation_requests = [
      ['DELETE', %r{^/api/v1/logout$}]
    ]
    config.mappings = { amigo: Amigo }
    config.revocation_strategies = { amigo: JwtDenylist }
  end
end