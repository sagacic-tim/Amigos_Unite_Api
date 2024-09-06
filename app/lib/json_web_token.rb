require 'jwt'

class JsonWebToken
  def self.jwt_secret_key
    Rails.application.config.jwt_secret_key
  end

  def self.encode(payload, exp = 15.minutes.from_now)
    payload[:exp] = exp.to_i
    payload[:jti] = SecureRandom.uuid # Ensure JTI is unique for each token
    secret = jwt_secret_key
    Rails.logger.info "JsonWebToken - JWT_SECRET_KEY during encoding: #{secret}" # Debugging line
    token = JWT.encode(payload, secret, 'HS256')
    Rails.logger.info "JsonWebToken - Encoded JWT, HS256: #{token}" # Debugging line
    token
  end

  def self.decode(token)
    secret = jwt_secret_key
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
end