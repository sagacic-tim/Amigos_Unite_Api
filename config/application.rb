require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module AmigosUniteApi
  class Application < Rails::Application
    config.load_defaults 7.1

    require "active_storage/engine"
    require_relative '../app/models/application_record'

    config.api_only = true
    config.active_job.queue_adapter = :async

    config.autoload_paths += %W(#{config.root}/app/lib)
    config.eager_load_paths += %W(#{config.root}/app/lib)
    config.autoload_paths += %W(#{config.root}/app/models)

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:5173'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
    
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
  end
end