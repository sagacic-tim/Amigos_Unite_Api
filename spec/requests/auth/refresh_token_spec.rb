
# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Auth Refresh Token", type: :request do
  let!(:amigo) { create(:amigo) }

  def json
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end

  def set_cookie_header
    response.headers["Set-Cookie"].to_s
  end

  def csrf_cookie_value_from_response
    m = set_cookie_header.match(/(?:^|;\s*)CSRF-TOKEN=([^;]+)/)
    return nil unless m

    CGI.unescape(m[1])
  end

  def mint_csrf!
    get "/api/v1/csrf", as: :json
    expect(response).to have_http_status(:ok)

    token = csrf_cookie_value_from_response
    expect(token).to be_present
    token
  end

  def bearer_from_response
    hdr = response.headers["Authorization"] || response.headers["authorization"]
    return hdr if hdr.present?

    body_token = json["token"]
    return nil unless body_token.present?

    body_token.to_s.start_with?("Bearer ") ? body_token : "Bearer #{body_token}"
  end

  it "rejects refresh without JWT" do
    csrf = mint_csrf!

    post "/api/v1/refresh_token",
         headers: { "X-CSRF-Token" => csrf },
         as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects refresh without CSRF even if JWT is present" do
    post "/api/v1/refresh_token",
         headers: auth_get_headers_for(amigo), # JWT only
         as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "refreshes with JWT + CSRF and returns a token" do
    csrf = mint_csrf!

    post "/api/v1/refresh_token",
         headers: auth_get_headers_for(amigo).merge("X-CSRF-Token" => csrf),
         as: :json

    expect(response).to have_http_status(:ok)

    token = bearer_from_response
    expect(token).to be_present
  end
end
