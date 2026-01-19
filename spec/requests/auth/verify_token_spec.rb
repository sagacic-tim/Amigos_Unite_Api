
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth Verify Token", type: :request do
  let!(:amigo) { create(:amigo) }

  it "rejects verify_token without JWT" do
    get "/api/v1/verify_token", as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts verify_token with JWT" do
    get "/api/v1/verify_token", headers: auth_get_headers_for(amigo), as: :json
    expect(response).to have_http_status(:ok)
  end
end
