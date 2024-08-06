# config/initializers/jwt.rb
Rails.application.config.jwt_secret_key = Rails.application.credentials[:devise_jwt_secret_key]
if Rails.application.config.jwt_secret_key.blank?
  Rails.logger.info "jwt.rb - JWT_SECRET_KEY is blank: \"#{Rails.application.config.jwt_secret_key}\""
  raise "JWT secret key is not set in credentials"
else
  Rails.logger.info "jwt.rb - JWT_SECRET_KEY: #{Rails.application.config.jwt_secret_key}"
end