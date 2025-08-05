# config/initializers/geocoder.rb

Geocoder.configure(
  # Primary geocoding service
  lookup: :google,

  # Secure API key from encrypted credentials
  api_key: Rails.application.credentials.dig(:google_maps),

  # Automatically use HTTPS in production (Google requires HTTPS anyway)
  use_https: true,

  # Timeout for API requests in seconds
  timeout: 20,

  # Use miles for distance calculations (set to :km if needed)
  units: :mi,

  # Default language for API responses
  language: :en,

  # Enable Rails logger for debugging geocoding issues
  logger: Rails.logger,

  # Cache responses using Rails.cache (not Redis directly)
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # IP-based geolocation service
  ip_lookup: :ipinfo_io,

  # Do not raise exceptions on geocoding errors (we handle them manually)
  always_raise: [],

  # Optional: handle rate limiting gracefully in your app
  # Google returns OVER_QUERY_LIMIT – we don’t raise, we log
  # You can inspect results.first.data['status'] in custom fallback

  # HTTPS headers (you can set referer headers here if needed for Google)
  http_headers: {},

  # Use strict address formatting (if needed, optional)
  # google_use_premise: true, # uncomment if using precise unit-level geocoding

  # Specify coordinate order in results (default is [lat, lon])
  # coordinates_order: [:lat, :lon]
)

# Optional manual fallback to open-source Nominatim
module GeocoderWithFallback
  def self.search_with_fallback(query, options = {})
    Geocoder.search(query, options)
  rescue => e
    Rails.logger.warn "[Geocoder Fallback] Primary lookup failed: #{e.message}"
    Geocoder.configure(lookup: :nominatim)
    result = Geocoder.search(query, options)
    Geocoder.configure(lookup: :google) # Restore default lookup
    result
  end
end
