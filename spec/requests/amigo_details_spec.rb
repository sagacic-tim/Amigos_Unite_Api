# frozen_string_literal: true

# spec/requests/amigo_details_spec.rb
require "rails_helper"

RSpec.describe "AmigoDetails", type: :request do
  let(:amigo)   { create(:amigo) }
  let!(:detail) { create(:amigo_detail, amigo: amigo, personal_bio: "Hello <b>world</b>") }

  # ApplicationController verifies CSRF by comparing:
  #   headers["X-CSRF-Token"]  vs  cookies["CSRF-TOKEN"]
  #
  # In request specs, set both explicitly: header + Cookie header.
  def csrf_token
    @csrf_token ||= SecureRandom.hex(16)
  end

  def with_csrf(headers = {})
    h = headers.dup
    h["X-CSRF-Token"] = csrf_token

    existing = h["Cookie"]
    h["Cookie"] = [existing, "CSRF-TOKEN=#{csrf_token}"].compact.join("; ")

    h
  end

  def amigo_detail_path
    "/api/v1/amigos/#{amigo.id}/amigo_detail"
  end

  it "rejects payloads that sanitize to no readable text (does not overwrite stored bio)" do
    original_bio = detail.reload.personal_bio.to_s

    patch(
      amigo_detail_path,
      params: { amigo_detail: { personal_bio: %(<img src=x onerror=alert(1)>) } },
      headers: with_csrf(auth_headers_for(amigo)),
      as: :json
    )

    expect(response).to have_http_status(:unprocessable_content) # 422

    # Ensure the invalid update did not overwrite existing content.
    expect(detail.reload.personal_bio.to_s).to eq(original_bio)

    # Optional: assert the specific validation message (if you want the API contract strict).
    # body = JSON.parse(response.body)
    # expect(body.dig("personal_bio")).to include("must contain readable text")
  end

  it "allows explicitly clearing personal_bio" do
    patch(
      amigo_detail_path,
      params: { amigo_detail: { personal_bio: "" } },
      headers: with_csrf(auth_headers_for(amigo)),
      as: :json
    )

    expect(response).to have_http_status(:ok)
    expect(detail.reload.personal_bio.to_s).to eq("")
  end

  it "preserves allowed inline tags when they contain readable text" do
    patch(
      amigo_detail_path,
      params: { amigo_detail: { personal_bio: "Hello <b>world</b> <i>friend</i>" } },
      headers: with_csrf(auth_headers_for(amigo)),
      as: :json
    )

    expect(response).to have_http_status(:ok)
    expect(detail.reload.personal_bio.to_s).to eq("Hello <b>world</b> <i>friend</i>")
  end
end
