class Amigo < ApplicationRecord
  # Virtual attribute for authenticating by either user_name or primary_email
  attr_accessor :login
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

  # Devise methods for primary_email as the authentication key
  def email_required?
    true
  end

  def email_changed?
    primary_email_changed?
  end

  def will_save_change_to_email?
    will_save_change_to_primary_email?
  end

  # login method is used to access the virtual attribute for authentication
  def login
    @login || user_name || primary_email
  end

  # Custom method to allow authentication with user_name or primary_email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login).downcase
    where(conditions.to_h).find_by(["lower(user_name) = :value OR lower(primary_email) = :value", { value: login }])
  end

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :primary_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { within: Devise.password_length }, confirmation: true
  validates :secondary_email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  
  # Phone validation
  validates :phone_1, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }
  validates :phone_2, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }

  validates :personal_bio, length: { maximum: 650 }

  private

  def remove_code_from_personal_bio
    self.personal_bio = Sanitize.fragment(self.personal_bio)
  end
end