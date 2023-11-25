# app/views/api/v1/event_participants/create.json.jbuilder

if @event_participant.persisted?
  json.partial! 'api/v1/event_participants/event_participant', event_participant: @event_participant
else
  json.errors @event_participant.errors.full_messages
end