class Event < ApplicationRecord
  # Events are related to a event_location_id which is a foreign
  # key to EventLocation
  
  belongs_to :event_location, class_name: 'EventLocation', foreign_key: 'event_location_id', optional: false
  # Direct association to an Amigo as the coordinator of the event
  belongs_to :coordinator, class_name: 'Amigo', foreign_key: 'event_coordinator_id'
  # Each event is associated with one event location
  has_one :event_location
  # Each event can have many participants
  has_many :event_participants
  # Each participant is associated with an amigo
  has_many :participants, through: :event_participants, source: :amigo
  # Ensure no duplicate event names at the same date and time

  validates :event_name, uniqueness: { 
    scope: [:event_date, :event_time], 
    message: "cannot have duplicate event names at the same date and time" 
  }, unless: :skip_uniqueness_validation?

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
