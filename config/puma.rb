# config/puma.rb

# Set the number of threads (min and max)
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 8 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold for development
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Set the port and SSL settings for development
if ENV.fetch("RAILS_ENV") { "development" } == "development"
  ssl_bind '127.0.0.1', '3001', {
    key: Rails.root.join("config/ssl/localhost.key").to_s,
    cert: Rails.root.join("config/ssl/localhost.crt").to_s,
    verify_mode: "none"
  }
end

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of workers (for multi-threading)
workers ENV.fetch("WEB_CONCURRENCY") { 2 } unless ENV.fetch("RAILS_ENV") { "development" } == "development"

# Preload the application for faster worker boot times
preload_app!

# Allow Puma to be restarted by `rails restart` command.
plugin :tmp_restart