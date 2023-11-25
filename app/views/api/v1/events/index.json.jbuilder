# app/views/api/v1/events/index.json.jbuilder

json.array! @events do |event|
  json.partial! 'api/v1/events/event', event: event
end
