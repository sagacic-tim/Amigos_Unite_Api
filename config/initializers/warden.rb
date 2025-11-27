# config/initializers/warden.rb

Rails.application.reloader.to_prepare do
  begin
    # Ensure the Amigo model and revocation strategy are loaded
    require_dependency 'amigo'
    require_dependency 'jwt_denylist'

    # Use the same secret source as Devise and jwt.rb
    jwt_secret =
      Rails.application.credentials.dig(:devise, :jwt_secret_key) ||
      ENV['DEVISE_JWT_SECRET_KEY']

    if jwt_secret.blank?
      Rails.logger.warn "[Warden/JWT] Missing JWT secret key. " \
                        "Set devise.jwt_secret_key in credentials or DEVISE_JWT_SECRET_KEY."
    else
      Rails.logger.info "[Warden/JWT] Loaded JWT secret key successfully."
    end

    Warden::JWTAuth.configure do |config|
      config.secret = jwt_secret

      # These should mirror your Devise jwt config; they are harmless if
      # you are not using Devise's sign_in/sign_out for JWT dispatch.
      config.dispatch_requests = [
        ['POST',   %r{^/api/v1/login$}],
        ['DELETE', %r{^/api/v1/logout$}]
      ]

      config.revocation_requests = [
        ['DELETE', %r{^/api/v1/logout$}]
      ]

      config.mappings = { amigo: Amigo }
      config.revocation_strategies = { amigo: JwtDenylist }
    end
  rescue => e
    Rails.logger.error "[Warden/JWT] configuration failed: #{e.class}: #{e.message}"
    raise
  end
end
