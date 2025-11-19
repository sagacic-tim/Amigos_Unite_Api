
# app/serializers/event_serializer.rb
class EventSerializer < ActiveModel::Serializer
  attributes :id,
             :event_name,
             :event_type,
             :event_speakers_performers,
             :event_date,
             :event_time,
             :description,
             :status,
             :status_label,
             :lead_coordinator_id,
             :formatted_event_date,
             :formatted_event_time,
             :created_at,
             :updated_at

  # Optional: include the lead coordinator as an Amigo.
  # This assumes the Event model has:
  #   belongs_to :lead_coordinator, class_name: "Amigo"
  #
  belongs_to :lead_coordinator, serializer: AmigoSerializer

  # Ensure we always return an array (never nil) to the FE
  def event_speakers_performers
    object.event_speakers_performers || []
  end

  # Keep the raw enum integer in :status, but provide a human-friendly string
  def status_label
    object.status.to_s  # e.g., "planning", "active", "completed", "canceled"
  end

  def formatted_event_date
    object.event_date&.strftime("%Y-%m-%d")
  end

  def formatted_event_time
    # If event_time is a Time or ActiveSupport::TimeWithZone
    object.event_time&.strftime("%H:%M:%S")
  end
end
