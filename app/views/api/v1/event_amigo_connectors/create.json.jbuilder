# app/views/api/v1/event_amigo_connectors/create.json.jbuilder

json.message 'Event Amigo Connector successfully created'
json.event_amigo_connector do
  json.partial! 'api/v1/event_amigo_connectors/event_amigo_connector', event_amigo_connector: @event_amigo_connector
end
