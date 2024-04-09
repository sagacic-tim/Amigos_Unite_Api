# app/views/api/v1/event_amigo_connectors/create.json.jbuilder

if @event_amigo_connector.persisted?
  json.partial! 'api/v1/event_amigo_connectors/event_amigo_connector', event_amigo_connector: @event_amigo_connector
else
  json.errors @event_amigo_connector.errors.full_messages
end
