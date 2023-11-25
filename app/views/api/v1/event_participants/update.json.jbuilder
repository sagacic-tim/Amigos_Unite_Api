# app/views/api/v1/event_participants/update.json.jbuilder

if @event_participant.errors.any?
  json.errors @event_participant.errors.full_messages
else
  json.partial! 'api/v1/event_participants/event_participant', event_participant: @event_participant
end