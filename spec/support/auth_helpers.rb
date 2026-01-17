# spec/support/suth_helpers.rb

# frozen_string_literal: true

module AuthHelpers
  def ensure_https!
    https! if respond_to?(:https!)
  end

  def csrf_path
    "/api/v1/csrf"
  end

  # Fetches a CSRF token in a way that is compatible with your ApplicationController:
  # - set_csrf_cookie runs on API GETs and sets cookies['CSRF-TOKEN'] with secure: true
  # - verify_csrf_token requires BOTH header token and cookie token, and they must match
  #
  # This helper will:
  # 1) force HTTPS so the secure cookie is accepted by the test client
  # 2) hit /api/v1/csrf (public endpoint)
  # 3) prefer X-CSRF-Token response header if provided by the endpoint,
  #    otherwise fall back to the CSRF-TOKEN cookie value
  def fetch_csrf_token!
    ensure_https!

    get csrf_path, headers: { "ACCEPT" => "application/json" }

    header_token = response.headers["X-CSRF-Token"].to_s
    cookie_token = response.cookies["CSRF-TOKEN"].to_s

    token = header_token.presence || cookie_token.presence

    raise "CSRF endpoint did not provide a CSRF token (header or cookie)" if token.blank?

    token
  end

  # JWT for Authorization header
  def jwt_for(amigo, expires_at: 12.hours.from_now)
    JsonWebToken.encode({ sub: amigo.id }, expires_at)
  end

  # Fast headers for GET requests (no CSRF handshake)
  def auth_get_headers_for(amigo)
    ensure_https!

    {
      "ACCEPT"        => "application/json",
      "Authorization" => "Bearer #{jwt_for(amigo)}"
    }
  end

  # Headers for mutating requests (PATCH/POST/PUT/DELETE) that require CSRF.
  # IMPORTANT: we do the CSRF handshake first so the cookie jar is populated.
  def auth_headers_for(amigo)
    csrf = fetch_csrf_token!
    ensure_https!

    {
      "ACCEPT"        => "application/json",
      "CONTENT_TYPE"  => "application/json",
      "Authorization" => "Bearer #{jwt_for(amigo)}",
      "X-CSRF-Token"  => csrf
    }
  end
end
