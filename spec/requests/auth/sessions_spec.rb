# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Auth Sessions", type: :request do
  let!(:amigo) { create(:amigo, password: password, password_confirmation: password) }
  let(:password) { "Password123!Pass" }

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

  describe "POST /api/v1/login" do
    it "rejects login without CSRF" do
      post "/api/v1/login",
           params: {
             amigo: {
               login: (amigo.try(:user_name) || amigo.try(:email)),
               password: password
             }
           },
           as: :json

      # If you enforce CSRF on login (recommended under your current contract),
      # this should be 401 (or whatever your verify_csrf_token uses).
      expect(response).to have_http_status(:unauthorized)
    end

    it "logs in with CSRF and returns/sets auth material" do
      csrf = mint_csrf!

      post "/api/v1/login",
           params: {
             amigo: {
               # Your app typically supports user_name login; fallback to email if needed.
               login: (amigo.try(:user_name) || amigo.try(:email)),
               password: password
             }
           },
           headers: { "X-CSRF-Token" => csrf },
           as: :json

      expect(response).to have_http_status(:ok)

      # Token may be in Authorization header OR JSON body (depending on your SessionsController).
      # We assert at least one is present.
      token = bearer_from_response
      expect(token).to be_present
    end
  end

  describe "DELETE /api/v1/logout" do
    it "requires JWT" do
      csrf = mint_csrf!

      delete "/api/v1/logout",
             headers: { "X-CSRF-Token" => csrf },
             as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "logs out with JWT + CSRF" do
      csrf = mint_csrf!

      post "/api/v1/login",
           params: {
             amigo: {
               login: (amigo.try(:user_name) || amigo.try(:email)),
               password: password
             }
           },
           headers: { "X-CSRF-Token" => csrf },
           as: :json

      expect(response).to have_http_status(:ok)
      bearer = bearer_from_response
      expect(bearer).to be_present

      # Rotation is OK; mint a fresh CSRF before mutation if you prefer.
      csrf2 = mint_csrf!

      delete "/api/v1/logout",
             headers: {
               "Authorization" => bearer,
               "X-CSRF-Token" => csrf2
             },
             as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
``
