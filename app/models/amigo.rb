class Amigo < ApplicationRecord
  # === Associations ===
  has_one_attached :avatar
  has_one  :amigo_detail,    dependent: :destroy
  has_many :amigo_locations, dependent: :destroy
  has_many :lead_coordinator_for_events, class_name: 'Event', foreign_key: 'lead_coordinator_id'
  has_many :event_amigo_connectors
  has_many :events, through: :event_amigo_connectors

  # === Devise Modules ===
  # Using denylist strategy (JwtDenylist table). Do NOT include JTIMatcher.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :confirmable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Virtual attribute provided by the client when logging in
  # (see config/initializers/devise.rb -> config.authentication_keys = [:login_attribute])
  attr_accessor :login_attribute

  # === Validations ===
  validates :first_name, :last_name,
            presence: true,
            length:   { maximum: 50 }

  # If you require usernames for your app, keep presence: true.
  validates :user_name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 50 },
            format: { with: /\A[a-zA-Z0-9_]+\z/ }

  # Devise’s :validatable already validates presence+format of email;
  # but we keep uniqueness case-insensitive explicitly.
  validates :email,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :secondary_email,
            allow_blank: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # Phones should be E.164; uniqueness is meaningful after normalization
  validates :phone_1,
            uniqueness: true,
            allow_blank: true,
            format: { with: /\A\+\d{6,15}\z/ }

  validates :phone_2,
            uniqueness: true,
            allow_blank: true,
            format: { with: /\A\+\d{6,15}\z/ }

  validates :avatar,
            content_type: ['image/png', 'image/jpg', 'image/jpeg', 'image/svg+xml']

  # If you want to allow signup WITHOUT email or username,
  # uncomment this custom rule and relax the two validations above accordingly.
  # validate :at_least_one_identifier_present

  # === Callbacks ===
  before_validation :normalize_identifiers
  after_commit :process_avatar, if: -> { avatar.attached? }

  # === Authentication hook used by Devise (because authentication_keys = [:login_attribute]) ===
  # Allows login by username OR email OR phone (phone_1/phone_2).
  def self.find_for_database_authentication(warden_conditions)
    raw = warden_conditions[:login_attribute].to_s.strip
    return nil if raw.blank?

    login_down = raw.downcase
    phone_norm = normalize_phone(raw) # E.164 or nil

    where(
      "LOWER(user_name) = :login OR LOWER(email) = :login OR phone_1 = :phone OR phone_2 = :phone",
      login: login_down, phone: phone_norm
    ).first
  end

  # === Roles / helpers ===
  def admin?
    role == 'admin' || is_admin
  end

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
    event_amigo_connectors.includes(:event).map { |c| { event_id: c.event_id, role: c.role } }
  end

  # === Avatar helpers ===
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

  # === JSON presentation ===
  def as_json(options = {})
    super(options).merge(
      phone_1: international_phone(phone_1),
      phone_2: international_phone(phone_2)
    )
  end

  private

  # If you want to allow signup without email/username, enable and relax validations above.
  def at_least_one_identifier_present
    if [user_name, email, phone_1, phone_2].all?(&:blank?)
      errors.add(:base, "Provide at least one of username, email, or phone.")
    end
  end

  def normalize_identifiers
    self.user_name = user_name&.strip
    self.email     = email&.strip&.downcase
    self.phone_1   = self.class.normalize_phone(phone_1)
    self.phone_2   = self.class.normalize_phone(phone_2)
  end

  def self.normalize_phone(value)
    return nil if value.blank?
    Phonelib.parse(value).e164.presence
  end

  def international_phone(phone)
    phone.present? ? Phonelib.parse(phone).international : nil
  end

  def process_avatar
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
