json.array! @event_coordinators do |event_coordinator|
  json.partial! 'event_coordinator', event_coordinator: event_coordinator
end