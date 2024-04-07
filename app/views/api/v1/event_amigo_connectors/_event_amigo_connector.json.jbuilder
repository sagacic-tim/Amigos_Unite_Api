json.extract! event_amigo_connector, :id, :role
json.amigo do
  json.partial! 'api/v1/amigos/amigo', amigo: event_amigo_connector.amigo
end

json.created_at event_amigo_connector.created_at
json.updated_at event_amigo_connector.updated_at