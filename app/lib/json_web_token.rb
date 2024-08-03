# lib/json_web_token.rb
require 'jwt'
require_relative '../models/jwt_denylist'

class JsonWebToken
  def self.jwt_secret_key
    Rails.application.config.jwt_secret_key || Rails.application.credentials[:devise_jwt_secret_key]
  end

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:jti] = SecureRandom.uuid # Ensure JTI is unique for each token
    secret = jwt_secret_key
    raise "JWT secret key is not set" if secret.blank? # Add a check to ensure secret is not nil or empty
    Rails.logger.info "JsonWebToken - JWT_SECRET_KEY during encoding: #{secret}" # Debugging line
    token = JWT.encode(payload, secret, 'HS256')
    Rails.logger.info "JsonWebToken - Encoded JWT, HS256: #{token}" # Debugging line
    token
  end

  def self.decode(token)
    secret = jwt_secret_key
    raise "JWT secret key is not set" if secret.blank? # Add a check to ensure secret is not nil or empty
    Rails.logger.info "JsonWebToken - Decoding JWT: #{token}" # Debugging line
    Rails.logger.info "JsonWebToken - JWT_SECRET_KEY during decoding: #{secret}" # Debugging line

    begin
      body = JWT.decode(token, secret, true, { algorithm: 'HS256' })[0]
      Rails.logger.info "JsonWebToken - Decoded JWT, HS256 body: #{body}" # Debugging line
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError => e
      Rails.logger.error "JsonWebToken - JWT Decode Error: #{e.message}" # Debugging line
      { error: e.message }
    end
  end

  def self.add_to_denylist(jti)
    JWTDenylist.create!(jti: jti)
  end
end