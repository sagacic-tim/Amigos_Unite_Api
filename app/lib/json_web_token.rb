# app/lib/json_web_token.rb
require 'jwt'

class JsonWebToken
  ALGORITHM = 'HS256'.freeze
  LEEWAY   = 5

  class << self
    # Single source of truth for the secret
    def jwt_secret_key
      Rails.application.credentials.dig(:devise, :jwt_secret_key)
    end

    # Sign a token; you can pass a custom exp (Time)
    def encode(payload, exp = 15.minutes.from_now)
      data = payload.dup
      data[:exp] = exp.to_i
      data[:iat] = Time.now.to_i
      data[:jti] ||= SecureRandom.uuid

      token = JWT.encode(data, jwt_secret_key, ALGORITHM)
      Rails.logger.info("[JWT] encode jti=#{data[:jti]} iat=#{data[:iat]} exp=#{data[:exp]}")
      token
    rescue => e
      Rails.logger.error("[JWT] encode error: #{e.class}: #{e.message}")
      raise
    end

    # Verify signature + claims; allow small clock skew
    def decode(token)
      decoded = JWT.decode(
        token,
        jwt_secret_key,
        true,
        { algorithm: ALGORITHM, leeway: LEEWAY }
      ).first
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::ExpiredSignature
      Rails.logger.warn("[JWT] decode expired")
      raise
    rescue JWT::DecodeError => e
      Rails.logger.warn("[JWT] decode error: #{e.message}")
      raise
    end

    # For refresh: verify signature but ignore exp
    def decode_allow_expired(token)
      decoded = JWT.decode(
        token,
        jwt_secret_key,
        true,
        { algorithm: ALGORITHM, verify_expiration: false }
      ).first
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::DecodeError => e
      Rails.logger.warn("[JWT] decode_allow_expired error: #{e.message}")
      raise
    end
  end
end
