# app/lib/json_web_token.rb
require 'jwt'

class JsonWebToken
  ALGORITHM = 'HS256'.freeze

  class << self
    def jwt_secret_key
      Rails.application.config.jwt_secret_key
    end

    def encode(payload, exp = 15.minutes.from_now)
      payload[:exp] = exp.to_i
      payload[:iat] = Time.now.to_i
      payload[:jti] ||= SecureRandom.uuid

      token = JWT.encode(payload, jwt_secret_key, ALGORITHM)
      Rails.logger.info("[JWT] Token encoded with JTI=#{payload[:jti]}, IAT=#{payload[:iat]}, EXP=#{payload[:exp]}")
      token
    rescue => e
      Rails.logger.error("[JWT] Encoding error: #{e.class} - #{e.message}")
      raise
    end

    def decode(token)
      decoded = JWT.decode(token, jwt_secret_key, true, algorithm: ALGORITHM)[0]
      Rails.logger.info("[JWT] Token decoded successfully: #{decoded}")
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::ExpiredSignature
      Rails.logger.warn("[JWT] Token has expired")
      raise JWT::ExpiredSignature, 'Token has expired'
    rescue JWT::DecodeError => e
      Rails.logger.warn("[JWT] Decode error: #{e.message}")
      raise JWT::DecodeError, 'Invalid token'
    end

    def extract_expiration(token)
      payload = decode(token)
      extract_timestamp(payload[:exp])
    rescue => e
      Rails.logger.error("[JWT] Could not extract expiration: #{e.message}")
      nil
    end

    def extract_issued_at(token)
      payload = decode(token)
      extract_timestamp(payload[:iat])
    rescue => e
      Rails.logger.error("[JWT] Could not extract issued-at: #{e.message}")
      nil
    end

    private

    def extract_timestamp(timestamp)
      return nil unless timestamp
      Time.at(timestamp).in_time_zone
    end
  end
end
