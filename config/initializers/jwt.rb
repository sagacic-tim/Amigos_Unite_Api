# config/initializers/jwt.rb
#
# Make sure the JWT secret is present in credentials.
secret = Rails.application.credentials.dig(:devise, :jwt_secret_key)
if secret.blank?
  raise "JWT secret key is not set in credentials. Add devise.jwt_secret_key to config/credentials/*.yml.enc"
end

Rails.logger.info "[JWT] Loaded secret key successfully."
