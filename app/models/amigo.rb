class Amigo < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Virtual attribute for authenticating by either user_name or email
  attr_accessor :login_attribute

  has_many :amigo_locations, dependent: :destroy
  has_one :amigo_detail, dependent: :destroy
  has_one_attached :avatar
  # As a coordinator, an Amigo can coordinate many events
  has_many :event_coordinators
  # An Amigo can coordinate many events
  has_many :coordinated_events, class_name: 'Event', foreign_key: 'event_coordinator_id'

  # As a participant, an Amigo can participate in many events
  has_many :event_participants
  has_many :participated_events, through: :event_participants, source: :event

  validates :phone_1, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_1.present? }
  validates :phone_2, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_2.present? }

  # Phone validation with uniqueness
  before_validation :normalize_phone_numbers

  # Include all devise modules.
  devise  :database_authenticatable,
          :registerable,
          :recoverable,
          # :rememberable,
          :validatable,
          # :confirmable,
          # :lockable,
          # :timeoutable,
          # :trackable,
          # :omniauthable,
          :jwt_authenticatable,
          jwt_revocation_strategy: self

  # login method is used to access the virtual attribute for authentication
  def login_attribute
    @login_attribute || user_name || email
  end

  # Custom method to allow authentication with user_name or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login_attribute)&.downcase
    find_by(["lower(user_name) = :value OR lower(email) = :value", { value: login }])
  end  

  # Method to retrieve unique locations coordinated by an Amigo
  def coordinated_locations
    EventLocation.joins(:events)
                 .where(events: { event_coordinator_id: self.id })
                 .distinct
  end

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :secondary_email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  

  private

  def normalize_phone_numbers
    self.phone_1 = Phonelib.parse(phone_1).e164 if phone_1.present?
    self.phone_2 = Phonelib.parse(phone_2).e164 if phone_2.present?
  end
end