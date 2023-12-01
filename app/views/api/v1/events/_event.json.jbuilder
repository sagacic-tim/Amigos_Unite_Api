json.extract! event,
  :id,
  :event_name,
  :event_type,
  :event_speakers_performers,
  :event_date,
  :event_time

json.event_coordinator do
  json.partial! 'api/v1/amigos/amigo', amigo: event.event_coordinator
end

# Render the event locations using the connectors
json.event_locations do
  json.array! event.event_location_connectors do |connector|
    json.partial! 'api/v1/event_locations/event_location', event_location: connector.event_location
  end
end

json.created_at event.created_at
json.updated_at event.updated_at