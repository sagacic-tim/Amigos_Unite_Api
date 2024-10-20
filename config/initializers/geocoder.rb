Geocoder.configure(
  # Name of geocoding service (symbol)
  lookup: :google,

  # API key for geocoding service
  api_key: Rails.application.credentials.dig(:google_maps),
  
  # Use HTTPS (recommended for production, can be false in development)
  use_https: true,

  # Timeout in seconds for geocoding requests
  timeout: 20,

  logger: Rails.logger # Enable logging
)