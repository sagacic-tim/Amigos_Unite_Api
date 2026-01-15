# frozen_string_literal: true

module AuthHelpers
  def ensure_https!
    https! if respond_to?(:https!)
  end

  def csrf_path
    "/api/v1/csrf"
  end

  # Calls your CSRF handshake endpoint, which sets:
  # - cookies['CSRF-TOKEN'] (secure: true)
  # - response header X-CSRF-Token
  #
  # Returns the header token (must equal cookie token).
  def fetch_csrf_token!
    ensure_https!

    get csrf_path, headers: { "ACCEPT" => "application/json" }

    token = response.headers["X-CSRF-Token"].to_s
    raise "CSRF endpoint did not return X-CSRF-Token" if token.empty?

    token
  end

  # Your Authentication concern supports Authorization or cookies.signed[:jwt].
  # Use Authorization for request specs; it avoids cookie signing concerns.
  def jwt_for(amigo, expires_at: 12.hours.from_now)
    JsonWebToken.encode({ sub: amigo.id }, expires_at)
  end

  # Headers for POST/PUT/PATCH/DELETE that must pass verify_csrf_token
  def auth_headers_for(amigo)
    ensure_https!

    csrf = fetch_csrf_token!
    jwt  = jwt_for(amigo)

    {
      "ACCEPT"        => "application/json",
      "CONTENT_TYPE"  => "application/json",
      "Authorization" => "Bearer #{jwt}",
      "X-CSRF-Token"  => csrf
    }
  end

  def csrf_headers
    ensure_https!
    { "ACCEPT" => "application/json", "X-CSRF-Token" => fetch_csrf_token! }
  end
end
