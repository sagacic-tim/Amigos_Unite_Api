# puts "amigo.rb - Loading Amigo Model Top of File..."
# puts "amigo.rb - Active Storage Loaded if ActriveStorage Defined" if defined?(ActiveStorage::Engine)

class Amigo < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  if defined?(ActiveStorage::Engine)
    puts "amigo.rb - Active Storage is defined in Amigo before has_one_attached"
  end

  has_one_attached :avatar

  if defined?(ActiveStorage::Engine)
    puts "amigo.rb - Active Storage is defined in Amigo after has_one_attached"
  end

#   # Virtual attribute for authenticating by either user_name or email
  attr_accessor :login_attribute
  after_commit :process_avatar, if: -> { avatar.attached? }

  has_many :amigo_locations, dependent: :destroy

  # As the lead coordinator for events
  has_many :lead_coordinator_for_events, class_name: 'Event', foreign_key: 'lead_coordinator_id'

  # As a participant in events, potentially including assistant coordinator roles
  has_many :event_amigo_connectors
  has_many :events, through: :event_amigo_connectors

  has_one :amigo_detail, dependent: :destroy

  validates :unformatted_phone_1, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { unformatted_phone_1.present? }
  validates :unformatted_phone_2, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { unformatted_phone_2.present? }

  # Phone validation with uniqueness
  before_validation :normalize_phone_numbers

  # Include all devise modules.
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  def event_roles
    event_amigo_connectors.includes(:event).map do |connector|
      { event_id: connector.event_id, role: connector.role }
    end
  end          

  # login method is used to access the virtual attribute for authentication
  def login_attribute
    @login_attribute || user_name || email || unformatted_phone_1
  end

  # Custom method to allow authentication with user_name, email, or phone
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login_attribute)&.downcase
    Rails.logger.debug "Attempting login with: #{login}"  
    return nil unless login
    Rails.logger.debug "Conditions: #{conditions.inspect}"
    where(conditions.to_h).where(
      ["lower(user_name) = :value OR lower(email) = :value OR unformatted_phone_1 = :value OR unformatted_phone_2 = :value", { value: login }]
    ).first
  end

  # Method to retrieve unique locations coordinated by an Amigo
  def coordinated_locations
    EventLocation.joins(:events)
                 .where(events: { event_coordinator_id: self.id })
                 .distinct
  end

  # Method to get the URL of the avatar
  def avatar_url
    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true) if avatar.attached?
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
    event_amigo_connectors.find_by(event: event, role: 'lead_coordinator').present?
  end

  def assistant_coordinator_for?(event)
    event_amigo_connectors.find_by(event: event, role: 'assistant_coordinator').present?
  end

  def can_remove_participant?(event)
    lead_coordinator_for?(event) || assistant_coordinator_for?(event)
  end

  def can_manage?(amigo)
    return false unless amigo  # Return false if amigo is nil
    self.id == amigo.id
  end

  # Add these formatted phone numbers to the JSON representation
  def as_json(options = {})
    super(options.merge(except: [:jti])).merge(
      phone_1: Phonelib.parse(unformatted_phone_1).international,
      phone_2: Phonelib.parse(unformatted_phone_2).international
    )
  end

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :secondary_email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :avatar, content_type: ['image/png', 'image/jpg', 'image/jpeg', 'image/svg+xml']
  

  private

  def normalize_phone_numbers
    self.unformatted_phone_1 = Phonelib.parse(unformatted_phone_1).e164 if unformatted_phone_1.present?
    self.unformatted_phone_2 = Phonelib.parse(unformatted_phone_2).e164 if unformatted_phone_2.present?
  end

  def process_avatar
    processed_avatar = ImageProcessing::Vips
                       .source(avatar.download)
                       .resize_to_limit(300, 300)
                       .convert("png")
                       .call

    avatar.attach(io: File.open(processed_avatar.path), filename: "avatar.png", content_type: "image/png")
  end
end