# config/application.rb
require_relative 'boot'

# For API-only apps you can load just what you need, or keep rails/all.
# Keeping rails/all is fine; api_only will slim the middleware stack.
require 'rails/all'

Bundler.require(*Rails.groups)

module AmigosUniteApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # --- Cookies & Session (required for CSRF) ---
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use Rack::Attack
    config.middleware.use(
      ActionDispatch::Session::CookieStore,
      key:       '_amigos_unite_session',
      same_site: :none,    # cross-site SPA <-> API
      secure:    true,     # you're on HTTPS (https://localhost)
      httponly:  true,
      path:      '/'
    )

    # You already call protect_from_forgery in your controllers.
    # No need to also set default_protect_from_forgery here.
    # (Remove this if you had it) -> config.action_controller.default_protect_from_forgery = true

    # --- CORS is configured in config/initializers/cors.rb ---

    # --- Rack::Attack: place early in the stack so it can short-circuit ---
    # If Rack::Runtime isn't present in api_only, insert before Rack::Head (or just use `use`).
    config.middleware.insert_before Rack::Runtime, Rack::Attack rescue config.middleware.use Rack::Attack

    # --- Devise / Warden ---
    # devise-jwt hooks into Warden automatically; you don't need to add Warden::JWTAuth::Middleware manually.
    # Remove this if you have it:
    # config.middleware.use Warden::JWTAuth::Middleware

    # --- Serializer / Jobs ---
    ActiveModelSerializers.config.adapter = :json_api
    config.active_job.queue_adapter = :async

    # --- Autoload/eager-load libraries under app/lib (where JsonWebToken lives) ---
    config.autoload_paths << Rails.root.join('app/lib')
    config.eager_load_paths << Rails.root.join('app/lib')
    config.active_job.queue_adapter = :sidekiq
  end
end
