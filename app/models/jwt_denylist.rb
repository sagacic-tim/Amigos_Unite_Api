# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  self.table_name = 'jwt_denylist'

  validates :jti, presence: true, uniqueness: true

  def self.jwt_revoked?(payload, user)
    Rails.logger.debug "JwtDenylist - Checking if JWT is revoked with payload: #{payload}"
    exists?(jti: payload['jti'])
  end

  def self.revoke_jwt(payload, user)
    Rails.logger.debug "JwtDenylist - Revoking JWT with payload: #{payload}"
    jti = payload['jti']
    exp = payload['exp']

    if jti && exp
      create!(jti: jti, exp: Time.at(exp))
    else
      Rails.logger.error "JwtDenylist - Missing jti or exp in payload: #{payload}"
      raise "Invalid payload: missing jti or exp"
    end
  end
end