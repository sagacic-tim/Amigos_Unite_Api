class Amigo < ApplicationRecord
  # Virtual attribute for authenticating by either user_name or email
  attr_accessor :login
  before_validation :remove_code_from_personal_bio
  before_validation :normalize_phone_numbers

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

  # login method is used to access the virtual attribute for authentication
  def login
    @login || user_name || email
  end

  # Custom method to allow authentication with user_name or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login).downcase
    where(conditions.to_h).find_by(["lower(user_name) = :value OR lower(email) = :value", { value: login }])
  end

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { within: Devise.password_length }, confirmation: true
  validates :secondary_email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  
  # Phone validation
  validates :phone_1, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line, :personal_number] }
  validates :phone_2, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line, :personal_number] }  

  validates :personal_bio, length: { maximum: 650 }

  private

  def remove_code_from_personal_bio
    self.personal_bio = Sanitize.fragment(self.personal_bio)
  end

  def normalize_phone_numbers
    self.phone_1 = Phonelib.parse(phone_1).e164 if phone_1.present?
    self.phone_2 = Phonelib.parse(phone_2).e164 if phone_2.present?
  end
end