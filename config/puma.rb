# config/puma.rb
require "etc"

# ---------- Basics ----------
cpu_count   = Etc.nprocessors
min_threads = ENV.fetch("RAILS_MIN_THREADS", "1").to_i
max_threads = ENV.fetch("RAILS_MAX_THREADS", cpu_count.to_s).to_i
threads min_threads, max_threads

env = ENV.fetch("RAILS_ENV", "development")
environment env

# Project root (without relying on Rails)
APP_ROOT = File.expand_path("..", __dir__)

if env == "development"
  # Longer timeout is nice in dev
  worker_timeout 3600

  # Cert/key live at the project root: ./localhost.pem, ./localhost-key.pem
  cert_path = File.join(APP_ROOT, "localhost.pem")
  key_path  = File.join(APP_ROOT, "localhost-key.pem")

  abort "Missing cert: #{cert_path}" unless File.exist?(cert_path)
  abort "Missing key:  #{key_path}"  unless File.exist?(key_path)

  # HTTPS only on 3001
  ssl_bind "0.0.0.0", "3001",
           cert: cert_path,
           key:  key_path,
           verify_mode: "none"

  # Do NOT call `port` here (that would also open plain HTTP).
else
  # Non-dev: workers & plain port (front with real TLS at a proxy)
  workers ENV.fetch("PUMA_MAX_WORKERS", (cpu_count).to_s).to_i
  preload_app!

  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end

  port ENV.fetch("PORT", "3001")
end

plugin :tmp_restart
