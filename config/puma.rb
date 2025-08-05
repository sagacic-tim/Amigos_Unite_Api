# config/puma.rb

require 'etc'

# —————————————————————————————————————————————
# 1) CPU‑based defaults for threads & workers
cpu_count   = Etc.nprocessors
min_threads = ENV.fetch("RAILS_MIN_THREADS") { 1 }.to_i
max_threads = ENV.fetch("RAILS_MAX_THREADS") { cpu_count }.to_i
max_workers = ENV.fetch("PUMA_MAX_WORKERS") { cpu_count/3 }.to_i

puts "Detected #{cpu_count} CPU cores"
puts "Puma threads: #{min_threads}-#{max_threads}, workers: #{max_workers}"

threads min_threads, max_threads
environment ENV.fetch("RAILS_ENV") { "development" }

# —————————————————————————————————————————————
# 2) Development: long timeout + SSL on 3001
if ENV.fetch("RAILS_ENV") == "development"
  worker_timeout 3600

  ssl_bind '0.0.0.0', '3001',
    key:  "/Users/drruby/ruby_projects/localhost+2-key.pem",
    cert: "/Users/drruby/ruby_projects/localhost+2.pem",
    verify_mode: "none"

  # if you still want HTTP on 3000 too, uncomment:
  # port ENV.fetch("PORT") { 3000 }

# —————————————————————————————————————————————
# 3) Production/Staging: clustered with on_worker_boot & HTTP
else
  workers max_workers
  preload_app!

  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end

  port ENV.fetch("PORT") { 3001 }
end

# —————————————————————————————————————————————
# 4) Allow bin/rails restart to work
plugin :tmp_restart
