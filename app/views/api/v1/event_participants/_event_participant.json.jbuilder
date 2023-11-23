json.extract! event_participant, :id
json.amigo do
  json.partial! 'api/v1/amigos/amigo', amigo: event_participant.amigo
end