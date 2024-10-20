class Amigo < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Associations
  has_one_attached :avatar
  has_many :amigo_locations, dependent: :destroy
  has_many :lead_coordinator_for_events, class_name: 'Event', foreign_key: 'lead_coordinator_id'
  has_many :event_amigo_connectors
  has_many :events, through: :event_amigo_connectors
  has_one :amigo_detail, dependent: :destroy

  # Devise Modules
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  # Validations
  validates :phone_1, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_1.present? }
  validates :phone_2, uniqueness: { case_sensitive: false, allow_blank: true }, if: -> { phone_2.present? }
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :secondary_email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :avatar, content_type: ['image/png', 'image/jpg', 'image/jpeg', 'image/svg+xml']

  # Callbacks
  before_validation :normalize_phone_numbers
  after_commit :process_avatar, if: -> { avatar.attached? }

  # Methods related to authentication
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login_attribute)&.downcase
    return nil unless login

    where(conditions.to_h).where(
      ["lower(user_name) = :value OR lower(email) = :value OR phone_1 = :value OR phone_2 = :value", { value: login }]
    ).first
  end

  def event_roles
    event_amigo_connectors.includes(:event).map do |connector|
      { event_id: connector.event_id, role: connector.role }
    end
  end

  # Methods related to avatar management
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

  # Role-related methods
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
    return false unless amigo
    self.id == amigo.id
  end

  # Format phone numbers in JSON representation
  def as_json(options = {})
    super(options.merge(except: [:jti])).merge(
      phone_1: Phonelib.parse(phone_1).international,
      phone_2: Phonelib.parse(phone_2).international
    )
  end

  private

  # Format phone numbers before saving
  def normalize_phone_numbers
    self.phone_1 = Phonelib.parse(phone_1).e164 if phone_1.present?
    self.phone_2 = Phonelib.parse(phone_2).e164 if phone_2.present?
  end

  # Resize and process avatar image
  def process_avatar
    processed_avatar = ImageProcessing::Vips
                       .source(avatar.download)
                       .resize_to_limit(300, 300)
                       .convert("png")
                       .call

    avatar.attach(io: File.open(processed_avatar.path), filename: "avatar.png", content_type: "image/png")
  end
end