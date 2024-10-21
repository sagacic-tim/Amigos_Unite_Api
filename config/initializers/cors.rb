# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://localhost:5173'
    resource '/api/v1/*',
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      expose: ['Authorization', 'Set-Cookie'], # If there are headers you need exposed to the client
      credentials: true # Allow cookies to be sent across domains
  end
end