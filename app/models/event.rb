class Event < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Virtual attribute for authenticating by either user_name or email
  attr_accessor :login_attribute
  # Associations
  
  # Each event is associated a lead_coordsinator
  belongs_to :lead_coordinator, class_name: 'Amigo'
  # Each event is associated with one or more event locations
  has_many :event_location_connectors
  has_many :event_locations, through: :event_location_connectors
  # Each event is associated wioth a igos as participants
  has_many :event_amigo_connectors
  has_many :amigos, through: :event_amigo_connectors

  # Validations
  validates :event_name, uniqueness: { 
    scope: [:event_date, :event_time], 
    message: "cannot have duplicate event names at the same date and time" 
  }

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

  public

  def as_json(options={})
    super(options).tap do |json|
      if json['event_time'].present?
        parsed_time = Time.parse(json['event_time'])
        json['event_time'] = parsed_time.strftime('%H:%M:%S')
      end
    end
  end

  private

  def skip_uniqueness_validation?
    event_name.blank? || event_date.blank? || event_time.blank? || !date_and_time_valid?
  end

  def date_and_time_valid?
    begin
      Date.parse(event_date.to_s)
      Time.parse(event_time.to_s)
      true
    rescue ArgumentError
      false
    end
  end
end
