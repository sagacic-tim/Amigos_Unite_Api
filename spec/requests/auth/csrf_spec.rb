# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Auth CSRF", type: :request do
  def set_cookie_header
    response.headers["Set-Cookie"].to_s
  end

  def csrf_cookie_value_from_response
    # CSRF-TOKEN=<value>; path=/; ...
    m = set_cookie_header.match(/(?:^|;\s*)CSRF-TOKEN=([^;]+)/)
    return nil unless m

    CGI.unescape(m[1])
  end

  it "GET /api/v1/csrf is public and mints a CSRF-TOKEN cookie" do
    get "/api/v1/csrf", as: :json

    expect(response).to have_http_status(:ok)
    expect(set_cookie_header).to include("CSRF-TOKEN=")

    token = csrf_cookie_value_from_response
    expect(token).to be_present
  end

  it "GET /api/v1/csrf returns a token consistently (cookie is the source of truth)" do
    get "/api/v1/csrf", as: :json

    expect(response).to have_http_status(:ok)
    expect(csrf_cookie_value_from_response).to be_present
  end
end

