class Amigo < ApplicationRecord
  before_validation :remove_code_from_personal_bio

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
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :personal_bio, length: { maximum: 650 }
  # email validation
  validates :primary_email, email: true
  validates :secondary_email, email: true, allow_blank: true
  #$ phone validation
  validates :phone_1, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }
  validates :phone_2, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }

  private

  def remove_code_from_personal_bio
    self.personal_bio = Sanitize.fragment(self.personal_bio)
  end
end
