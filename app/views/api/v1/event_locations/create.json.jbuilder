if @event_location.persisted?
  json.partial! 'api/v1/event_locations/event_location', event_location: @event_location
else
  json.errors @event_location.errors.full_messages
end