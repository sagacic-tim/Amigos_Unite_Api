# app/views/api/v1/event_location_connectors/create.json.jbuilder

json.event_location_connector do
  json.partial! 'api/v1/event_location_connectors/event_location_connector', event_location_connector: @event_location_connector
end