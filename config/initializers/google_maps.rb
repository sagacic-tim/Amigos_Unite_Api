
require 'google_maps_service'

GOOGLE_MAPS_API_KEY = Rails.application.credentials.google_maps_api_key

# Setup global parameters
GoogleMapsService.configure do |config|
  config.key = GOOGLE_MAPS_API_KEY
  config.retry_timeout = 20
  config.queries_per_second = 10
end

# Initialize client using global parameters
gmaps = GoogleMapsService::Client.new
