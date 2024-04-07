# app/views/api/v1/event_participants/index.json.jbuilder

json.array! @event_participants do |event_participant|
  json.partial! 'api/v1/event_participants/event_participant', event_participant: event_participant
end