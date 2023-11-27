# app/views/api/v1/event_locations/update.json.jbuilder

if @event_location.errors.any?
  json.errors @event_location.errors.full_messages
else
  json.partial! 'api/v1/event_locations/event_location', event_location: @event_location
end
