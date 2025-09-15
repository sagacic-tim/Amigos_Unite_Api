# config/initializers/rack_attack.rb
require 'rack/attack'

# Tiny in-memory store is fine in dev; use Redis in prod
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# Don’t throttle CORS preflight or CSRF token fetch
Rack::Attack.safelist('allow-preflight-and-csrf') do |req|
  req.options? || req.path == '/api/v1/csrf'
end

# Throttle login attempts by IP
Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.post? && req.path == '/api/v1/login'
end

# Throttle login attempts by credential (slow stuffing)
Rack::Attack.throttle('logins/login_attribute', limit: 5, period: 60.seconds) do |req|
  next unless req.post? && req.path == '/api/v1/login'
  begin
    raw = req.body.read
    data = JSON.parse(raw) rescue {}
    (data.dig('amigo', 'login_attribute') || '').downcase.presence
  ensure
    req.body.rewind
  end
end

# Throttle signups by IP
Rack::Attack.throttle('signups/ip', limit: 3, period: 10.minutes) do |req|
  req.ip if req.post? && req.path == '/api/v1/signup'
end

# NEW API: custom 429. Add CORS bits so the browser can read it.
Rack::Attack.throttled_responder = lambda do |request|
  match = request.env['rack.attack.match_data'] || {}
  retry_after = match[:period] || 60
  [
    429,
    {
      'Content-Type'                  => 'application/json',
      'Retry-After'                   => retry_after.to_s,
      'Access-Control-Allow-Origin'   => 'https://localhost:5173',
      'Access-Control-Allow-Credentials' => 'true'
    },
    [ { error: 'Too many requests' }.to_json ]
  ]
end
