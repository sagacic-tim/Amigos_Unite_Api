# config/puma.rb
require "etc"

# ---------- Environment ----------
env = ENV.fetch("RAILS_ENV", "development")
environment env

# ---------- Concurrency defaults (override via env vars) ----------
# Defaults:
#   RAILS_MIN_THREADS=1
#   RAILS_MAX_THREADS=5
#   PUMA_MAX_WORKERS=2
cpu_count   = Etc.nprocessors
min_threads = ENV.fetch("RAILS_MIN_THREADS", "1").to_i
max_threads = ENV.fetch("RAILS_MAX_THREADS", "5").to_i
threads min_threads, max_threads

port_number = ENV.fetch("PORT", "3001")

APP_ROOT = File.expand_path("..", __dir__)

# ---------- Dev HTTPS toggle ----------
# Set PUMA_DEV_SSL=true in development and provide:
#   ./localhost.pem and ./localhost-key.pem at APP_ROOT
use_dev_ssl = (env == "development" && ENV["PUMA_DEV_SSL"] == "true")

if use_dev_ssl
  worker_timeout 3600

  cert_path = File.join(APP_ROOT, "localhost.pem")
  key_path  = File.join(APP_ROOT, "localhost-key.pem")

  if File.exist?(cert_path) && File.exist?(key_path)
    ssl_bind "0.0.0.0", port_number,
             cert: cert_path,
             key:  key_path,
             verify_mode: "none"
  else
    warn "[puma] PUMA_DEV_SSL=true but cert/key not found; falling back to HTTP on PORT."
    bind "tcp://0.0.0.0:#{port_number}"
  end
else
  # Container-friendly HTTP bind (explicit)
  bind "tcp://0.0.0.0:#{port_number}"

  # Workers only outside development (avoid surprise for local dev)
  if env != "development"
    workers ENV.fetch("PUMA_MAX_WORKERS", "2").to_i
    preload_app!

    before_fork do
      ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
    end

    on_worker_boot do
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    end
  end
end

plugin :tmp_restart
