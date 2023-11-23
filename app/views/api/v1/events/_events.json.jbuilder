json.extract! event,
  :id,
  :event_name,
  :event_type,
  :event_speakers_performers,
  :event_date,
  :event_time
json.event_coordinator do
  json.partial! 'api/v1/amigos/amigo',
    amigo: event.event_coordinator
end
json.event_location do
  json.partial! 'api/v1/event_locations/event_location',
    event_location: event.event_location
end
json.created_at event.created_at
json.updated_at event.updated_at