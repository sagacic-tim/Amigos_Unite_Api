# config/initializers/jwt.rb
Rails.application.config.jwt_secret_key = Rails.application.credentials[:devise_jwt_secret_key]
if Rails.application.config.jwt_secret_key.blank?
  raise "JWT secret key is not set in credentials"
else
  Rails.logger.info "JWT_SECRET_KEY: #{Rails.application.config.jwt_secret_key}"
end