Geocoder.configure(
    # Name of geocoding service (symbol)
    lookup: :google,
    # API key for geocoding service
    api_key: Rails.application.credentials.google_maps_api_key,
    # Recommend using HTTPS for production set to false for development
    use_https: false,
    # Timeout in seconds for geocoding requests
    timeout: 3
)