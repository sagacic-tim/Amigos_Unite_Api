class Amigo < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # === Associations ===
  has_one_attached :avatar
  has_one :amigo_detail, dependent: :destroy
  has_many :amigo_locations, dependent: :destroy
  has_many :lead_coordinator_for_events, class_name: 'Event', foreign_key: 'lead_coordinator_id'
  has_many :event_amigo_connectors
  has_many :events, through: :event_amigo_connectors

  # === Devise Modules ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  # === Validations ===
  validates :first_name, :last_name, presence: true, length: { maximum: 50 }
  validates :user_name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: URI::MailTo::EMAIL_REGEXP
  validates :secondary_email, allow_blank: true, uniqueness: { case_sensitive: false }, format: URI::MailTo::EMAIL_REGEXP
  validates :phone_1, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone_2, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :avatar, content_type: ['image/png', 'image/jpg', 'image/jpeg', 'image/svg+xml']

  # === Callbacks ===
  before_validation :normalize_phone_numbers
  after_commit :process_avatar, if: -> { avatar.attached? }

  # === Authentication ===
  def self.find_for_database_authentication(warden_conditions)
    login = warden_conditions.delete(:login_attribute)&.downcase
    return nil unless login

    where(warden_conditions).where(
      "LOWER(user_name) = :val OR LOWER(email) = :val OR phone_1 = :val OR phone_2 = :val",
      val: login
    ).first
  end

  def admin?
    role == 'admin' || is_admin
  end

  # === Role Helpers ===
  def lead_coordinator_for?(event)
    event_amigo_connectors.exists?(event_id: event.id, role: 'lead_coordinator')
  end

  def assistant_coordinator_for?(event)
    event_amigo_connectors.exists?(event_id: event.id, role: 'assistant_coordinator')
  end

  def can_remove_participant?(event)
    lead_coordinator_for?(event) || assistant_coordinator_for?(event)
  end

  def can_manage?(amigo)
    amigo && id == amigo.id
  end

  def event_roles
    event_amigo_connectors.includes(:event).map do |connector|
      { event_id: connector.event_id, role: connector.role }
    end
  end

  # === Avatar Management ===
  def avatar_url
    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true) if avatar.attached?
  end

  def attach_avatar_by_identifier(avatar_identifier)
    avatar_path = Rails.root.join('lib/seeds/avatars', "#{avatar_identifier}.svg")

    if File.exist?(avatar_path)
      avatar.attach(io: File.open(avatar_path), filename: "#{avatar_identifier}.svg", content_type: "image/svg+xml")
    else
      errors.add(:avatar, "specified avatar does not exist")
    end
  end

  # === JSON Representation ===
  def as_json(options = {})
    super(options.merge(except: [:jti])).merge(
      phone_1: international_phone(phone_1),
      phone_2: international_phone(phone_2)
    )
  end

  private

  def normalize_phone_numbers
    self.phone_1 = e164_phone(phone_1)
    self.phone_2 = e164_phone(phone_2)
  end

  def e164_phone(phone)
    phone.present? ? Phonelib.parse(phone).e164 : nil
  end

  def international_phone(phone)
    phone.present? ? Phonelib.parse(phone).international : nil
  end

  def process_avatar
    begin
      processed = ImageProcessing::Vips
                    .source(avatar.download)
                    .resize_to_limit(300, 300)
                    .convert("png")
                    .call

      avatar.attach(io: File.open(processed.path), filename: "avatar.png", content_type: "image/png")
    rescue => e
      Rails.logger.error "Avatar processing failed for Amigo ##{id}: #{e.message}"
    end
  end
end
