json.array! @locations_of_host do |location|
  json.partial! 'api/v1/locations_of_host/location', location: location
end
