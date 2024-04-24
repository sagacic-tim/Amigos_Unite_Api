class Amigo < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Virtual attribute for authenticating by either user_name or email
  attr_accessor :login_attribute

  has_many :amigo_locations, dependent: :destroy

  # As the lead coordinator for events
  has_many :lead_coordinator_for_events, class_name: 'Event', foreign_key: 'lead_coordinator_id'

  # As a participant in events, potentially including assistant coordinator roles
  has_many :event_amigo_connectors
  has_many :events, through: :event_amigo_connectors

  has_one :amigo_detail, dependent: :destroy
  has_one_attached :avatar
  # As a coordinator, an Amigo can coordinate many events

  validates :phone_1, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_1.present? }
  validates :phone_2, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_2.present? }

  # Phone validation with uniqueness
  before_validation :normalize_phone_numbers

  # Include all devise modules.
  devise :database_authenticatable,
    :registerable,
    :recoverable,
    :rememberable,
    :validatable,
    # :confirmable,
    # :lockable,
    # :timeoutable,
    # :trackable,
    # :omniauthable,
    :jwt_authenticatable,
    jwt_revocation_strategy: self

  def event_roles
    event_amigo_connectors.includes(:event).map do |connector|
      { event_id: connector.event_id, role: connector.role }
    end
  end          

  # login method is used to access the virtual attribute for authentication
  def login_attribute
    @login_attribute || user_name || email || phone_1
  end

  # Custom method to allow authentication with user_name, email, or phone
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login_attribute)&.downcase
    Rails.logger.debug "Attempting login with: #{login}"  
    return nil unless login  # Return nil if no login credential was provided
  
    # login_identifier.downcase!  # Modify the login string to be all lowercase
    find_by(["lower(user_name) = :value OR lower(email) = :value OR phone_1 = :value", { value: login }])
  end

  # Method to retrieve unique locations coordinated by an Amigo
  def coordinated_locations
    EventLocation.joins(:events)
                 .where(events: { event_coordinator_id: self.id })
                 .distinct
  end

  def attach_avatar_by_identifier(avatar_identifier)
    avatar_filename = "#{avatar_identifier}.svg"
    avatar_path = Rails.root.join('lib', 'seeds', 'avatars', avatar_filename)

    if File.exist?(avatar_path)
      avatar.attach(io: File.open(avatar_path), filename: avatar_filename)
    else
      errors.add(:avatar, "specified avatar does not exist")
    end
  end

  def lead_coordinator_for?(event)
    event.lead_coordinator_id == self.id
  end

  def assistant_coordinator_for?(event)
    event.event_amigo_connectors.exists?(amigo_id: self.id, role: :assistant_coordinator)
  end

  def can_remove_participant?(event)
    lead_coordinator_for?(event) || assistant_coordinator_for?(event)
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