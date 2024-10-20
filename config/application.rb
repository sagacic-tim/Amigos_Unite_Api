require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AmigosUniteApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    ActiveModelSerializers.config.adapter = :json

    puts "Loading Application Configuration..."
    require "active_storage/engine"
    puts "Active Storage Loaded"
    require_relative '../app/models/application_record'
    puts "Active Storage Loaded" if defined?(ActiveStorage::Engine)

    config.api_only = true
    config.active_job.queue_adapter = :async

    config.autoload_paths += %W(#{config.root}/app/lib)
    config.eager_load_paths += %W(#{config.root}/app/lib)
    config.autoload_paths += %W(#{config.root}/app/models)

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:5173'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true  # Important to allow cookies
      end
    end

    # Include the necessary middleware for handling cookies
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
    config.autoload_paths += %W(#{config.root}/lib)
    config.middleware.use Warden::JWTAuth::Middleware
  end
end