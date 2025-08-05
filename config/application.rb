require_relative 'boot'
require 'rails/all'

# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
# require "action_controller/railtie"
# skip action_mailer / action_mailbox etc if unused
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie" # API-only typically doesn’t need assets


Bundler.require(*Rails.groups)

module AmigosUniteApi
  class Application < Rails::Application
    config.api_only = true
    config.load_defaults 7.1

    # === Session / Cookies (explicit, not via config.session_options) ===
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use(
      ActionDispatch::Session::CookieStore,
      key: '_amigos_unite_session',
      same_site: :none,
      secure: true,          # you always run HTTPS per your note
      httponly: true,
      path: '/'
    )

    # CSRF protection (needs session)
    config.action_controller.default_protect_from_forgery = true

    # Devise/JWT
    config.middleware.use Warden::JWTAuth::Middleware

    # Serializers / jobs / paths
    ActiveModelSerializers.config.adapter = :json_api
    config.active_job.queue_adapter = :async

    config.autoload_paths += %W(#{config.root}/app/lib #{config.root}/app/models #{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/app/lib)
  end
end

