json.extract! event_participant, :id
json.amigo do
  json.partial! 'api/v1/amigos/amigo', amigo: event_participant.amigo
end

json.created_at event_participant.created_at
json.updated_at event_participant.updated_at