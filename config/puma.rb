# config/puma.rb
require "etc"

# ---------- Basics ----------
cpu_count   = Etc.nprocessors
min_threads = ENV.fetch("RAILS_MIN_THREADS", "1").to_i
max_threads = ENV.fetch("RAILS_MAX_THREADS", cpu_count.to_s).to_i
threads min_threads, max_threads

env = ENV.fetch("RAILS_ENV", "development")
environment env

APP_ROOT = File.expand_path("..", __dir__)

# If you want HTTPS in local development, set:
#   PUMA_DEV_SSL=true
# and ensure ./localhost.pem and ./localhost-key.pem exist at APP_ROOT.
use_dev_ssl = (env == "development" && ENV["PUMA_DEV_SSL"] == "true")

if use_dev_ssl
  # Longer timeout is nice in dev
  worker_timeout 3600

  cert_path = File.join(APP_ROOT, "localhost.pem")
  key_path  = File.join(APP_ROOT, "localhost-key.pem")

  if File.exist?(cert_path) && File.exist?(key_path)
    ssl_bind "0.0.0.0", "3001",
             cert: cert_path,
             key:  key_path,
             verify_mode: "none"
  else
    warn "[puma] PUMA_DEV_SSL=true but cert/key not found; falling back to HTTP on PORT."
    port ENV.fetch("PORT", "3001")
  end
else
  # Container-friendly defaults:
  # - In development: single process, no workers, just bind to PORT over HTTP.
  # - In non-development: optional workers + preload.

  if env != "development"
    workers ENV.fetch("PUMA_MAX_WORKERS", cpu_count.to_s).to_i
    preload_app!

    on_worker_boot do
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    end
  end

  port ENV.fetch("PORT", "3001")
end

plugin :tmp_restart
