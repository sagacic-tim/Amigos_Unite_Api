# spec/requests/events_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events", type: :request do
  let!(:amigo) { create(:amigo) }

  # Prevent network calls from EventLocation callbacks during request specs.
  # Use conditional stubs so verifying partial doubles does not explode if methods differ.
  before do
    ensure_stub = lambda do |klass, method_name, return_value = nil|
      if klass.instance_methods.include?(method_name)
        allow_any_instance_of(klass).to receive(method_name).and_return(return_value)
      end
    end

    # Your GeocodableWithFallback plan referenced these names:
    ensure_stub.call(EventLocation, :fetch_geocoded_data, true)
    ensure_stub.call(EventLocation, :fetch_time_zone, nil)

    # If your current implementation still uses older callback names:
    ensure_stub.call(EventLocation, :geocode_with_fallback, true)

    # If anything attempts to fetch remote images, block it (defensive).
    allow(URI).to receive(:open).and_raise("Network calls are disabled in request specs")
  end

  describe "GET /api/v1/events" do
    it "returns ok with a valid bearer token" do
      create(:event, lead_coordinator: amigo)

      get "/api/v1/events", headers: auth_get_headers_for(amigo), as: :json

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first).to include("event_name")
    end

    it "returns unauthorized without a token" do
      get "/api/v1/events", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/events/:id" do
    it "returns ok with a valid bearer token" do
      event = create(:event, lead_coordinator: amigo)

      get "/api/v1/events/#{event.id}", headers: auth_get_headers_for(amigo), as: :json

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.fetch("id")).to eq(event.id)
      expect(body.fetch("event_name")).to eq(event.event_name)
    end

    it "returns unauthorized without a token" do
      event = create(:event, lead_coordinator: amigo)

      get "/api/v1/events/#{event.id}", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/events" do
    it "creates an event with CSRF (and creates lead connector + primary location)" do
      payload = {
        event: {
          event_name: "RSPEC Event",
          event_type: "Meetup",
          event_date: Date.current.to_s,
          event_time: "18:00",
          status: "planning",
          description: "hello",
          event_speakers_performers: ["Alice", " Bob ", ""],
          location: {
            business_name: "Dancing Mule Coffee Company",
            street_number: "1945",
            street_name: "South Glenstone Avenue",
            city: "Springfield",
            state_province: "Missouri",
            country: "United States",
            postal_code: "65804",
            has_food: true,
            has_drink: true
          }
        }
      }

      post "/api/v1/events",
           params: payload,
           headers: auth_headers_for(amigo),
           as: :json

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      created_id = body.fetch("id")

      created = Event.find(created_id)

      expect(created.lead_coordinator_id).to eq(amigo.id)
      expect(created.event_amigo_connectors.lead_coordinator.count).to eq(1)

      # Normalization behavior from Event#normalize_event_speakers
      expect(created.event_speakers_performers).to eq(["Alice", "Bob"])

      # Location was provided, so primary location should exist
      expect(created.primary_event_location).to be_present

      # If your controller includes the primary location on create, this asserts the contract:
      expect(body).to include("primary_event_location")
    end

    it "returns unauthorized without CSRF" do
      post "/api/v1/events",
           params: { event: { event_name: "No CSRF" } },
           headers: auth_get_headers_for(amigo), # JWT only (no CSRF)
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/events/:id" do
    it "rejects update when actor is not lead/admin/assistant" do
      lead = create(:amigo)
      event = create(:event, lead_coordinator: lead)
      create(:event_amigo_connector, :lead, event: event, amigo: lead)

      outsider = create(:amigo)

      patch "/api/v1/events/#{event.id}",
            params: { event: { description: "nope" } },
            headers: auth_headers_for(outsider),
            as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "updates core fields with CSRF when actor is lead" do
      event = create(:event, lead_coordinator: amigo)
      create(:event_amigo_connector, :lead, event: event, amigo: amigo)

      patch "/api/v1/events/#{event.id}",
            params: { event: { description: "Updated description" } },
            headers: auth_headers_for(amigo),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(event.reload.description).to eq("Updated description")
    end

    it "upserts primary location when location attrs are present" do
      event = create(:event, lead_coordinator: amigo)
      create(:event_amigo_connector, :lead, event: event, amigo: amigo)

      patch "/api/v1/events/#{event.id}",
            params: {
              event: {
                description: "Updated",
                location: {
                  business_name: "Updated Venue",
                  street_name: "Main",
                  city: "Springfield",
                  has_food: false
                }
              }
            },
            headers: auth_headers_for(amigo),
            as: :json

      expect(response).to have_http_status(:ok)

      event.reload
      expect(event.primary_event_location).to be_present
      expect(event.primary_event_location.business_name).to eq("Updated Venue")

      body = JSON.parse(response.body)
      expect(body).to include("primary_event_location")
    end
  end

  describe "DELETE /api/v1/events/:id" do
    it "rejects destroy when actor is assistant (not lead/admin)" do
      lead = create(:amigo)
      assistant = create(:amigo)
      event = create(:event, lead_coordinator: lead)
      create(:event_amigo_connector, :lead, event: event, amigo: lead)
      create(:event_amigo_connector, :assistant, event: event, amigo: assistant)

      delete "/api/v1/events/#{event.id}",
             headers: auth_headers_for(assistant),
             as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "destroys when actor is lead" do
      event = create(:event, lead_coordinator: amigo)
      create(:event_amigo_connector, :lead, event: event, amigo: amigo)

      delete "/api/v1/events/#{event.id}",
             headers: auth_headers_for(amigo),
             as: :json

      expect(response).to have_http_status(:ok)
      expect(Event.where(id: event.id)).to be_empty
    end
  end

  describe "GET /api/v1/events/my_events" do
    it "returns only events the current amigo manages (lead or assistant)" do
      lead_event = create(:event, lead_coordinator: amigo)
      create(:event_amigo_connector, :lead, event: lead_event, amigo: amigo)

      other_event = create(:event) # lead_coordinator is someone else (factory)
      create(:event_amigo_connector, :assistant, event: other_event, amigo: amigo)

      not_mine = create(:event)

      get "/api/v1/events/my_events", headers: auth_get_headers_for(amigo), as: :json

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body).to be_an(Array)

      ids = body.map { |h| h.fetch("id").to_i }

      expect(ids).to include(lead_event.id, other_event.id)
      expect(ids).not_to include(not_mine.id)
    end
  end
end
