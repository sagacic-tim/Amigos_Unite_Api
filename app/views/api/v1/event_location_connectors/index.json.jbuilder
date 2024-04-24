# app/views/api/v1/event_location_connectors/index.json.jbuilder
json.array! @event_location_connectors do |connector|
    json.partial! 'api/v1/event_location_connectors/event_location_connector', connector: connector
end  