class Amigo < ApplicationRecord
  # Include all devise modules.
  devise  :database_authenticatable,
          :registerable,
          :recoverable,
          :rememberable,
          :validatable,
          :confirmable,
          :lockable,
          :timeoutable,
          :trackable,
          :omniauthable,
          :jwt_authenticatable,
          jwt_revocation_strategy: JwtDenylist

  attr_writer :login

  def login
    @login || self.user_name || self.primary_email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(user_name) = :value OR lower(primary_email) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:user_name) || conditions.has_key?(:primary_email)
      where(conditions.to_h).first
    end
  end
end
