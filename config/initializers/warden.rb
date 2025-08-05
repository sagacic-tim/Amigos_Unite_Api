# config/initializers/warden.rb

Rails.application.reloader.to_prepare do
  begin
    # Ensure the Amigo model and revocation strategy are loaded
    require_dependency 'amigo'
    require_dependency 'jwt_denylist'

    Warden::JWTAuth.configure do |config|
      config.secret = Rails.application.credentials.dig(:devise_jwt_secret_key)

      if config.secret.blank?
        Rails.logger.warn "Warden JWT setup: Missing Devise JWT secret key in credentials!"
      end

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
  rescue => e
    Rails.logger.error "Warden JWTAuth configuration failed: #{e.message}"
    raise
  end
end
