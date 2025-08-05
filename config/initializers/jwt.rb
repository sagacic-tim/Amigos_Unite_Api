# config/initializers/jwt.rb

# Load JWT secret from Rails credentials
Rails.application.config.jwt_secret_key = Rails.application.credentials.dig(:devise, :jwt_secret_key)

# Ensure the key is present and valid
if Rails.application.config.jwt_secret_key.present?
  Rails.logger.info "[JWT] Loaded secret key successfully."
else
  Rails.logger.error "[JWT] JWT secret key is missing or blank in credentials under :devise -> :jwt_secret_key"
  raise "JWT secret key is not set in credentials. Please run `bin/rails credentials:edit` and add devise.jwt_secret_key"
end
