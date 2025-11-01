class Event < ApplicationRecord

  # Associations
  
  # Each event is associated a lead_coordsinator
  belongs_to :lead_coordinator, class_name: "Amigo", optional: true
  # Each event is associated with one or more event locations
  has_many :event_location_connectors, dependent: :destroy
  has_many :event_locations, through: :event_location_connectors
  # Each event is associated wioth a igos as participants
  has_many :event_amigo_connectors, dependent: :destroy
  has_many :amigos, through: :event_amigo_connectors

  before_validation :normalize_event_speakers

  # Validations
  validates :event_name, uniqueness: {
    scope: %i[event_date event_time],
    message: "cannot have duplicate event names at the same date and time"
  }, unless: :skip_uniqueness_validation?

  enum status: {
    planning: 0,
    active: 1,
    completed: 2,
    canceled: 3
  }

  public

  def as_json(options={})
    super(options).tap do |json|
      if json['event_time'].present?
        begin
          parsed_time = Time.parse(json['event_time'].to_s)
          json['event_time'] = parsed_time.strftime('%H:%M:%S')
          rescue ArgumentError
          # leave as-is if unparsable
        end
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

  def normalize_event_speakers
    self.event_speakers_performers =
      Array(event_speakers_performers).map { |s| s.to_s.strip }.reject(&:blank?)
  end

end
