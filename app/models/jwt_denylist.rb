# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  self.table_name = 'jwt_denylist'

  validates :jti, presence: true, uniqueness: true

  def self.jwt_revoked?(payload, user)
    exists?(jti: payload['jti'])
  end

  def self.revoke_jwt(payload, user)
    create!(jti: payload['jti'], exp: Time.at(payload['exp']))
  end
end