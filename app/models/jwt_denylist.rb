# app/models/jwt_denylist.rb
class JWTDenylist < ApplicationRecord
  validates :jti, presence: true, uniqueness: true

  def self.add(token)
    decoded_token = JsonWebToken.decode(token)
    if decoded_token[:error].blank?
      jti = decoded_token[:jti]
      create!(jti: jti) if jti.present?
    end
  end

  def self.include?(token)
    decoded_token = JsonWebToken.decode(token)
    jti = decoded_token[:jti]
    exists?(jti: jti)
  end
end