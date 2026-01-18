
# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventLocation, type: :model do
  describe "factory" do
    it "has a valid factory" do
      # Avoid any external calls from GeocodableWithFallback
      allow_any_instance_of(EventLocation).to receive(:geocode_with_fallback)
      allow_any_instance_of(EventLocation).to receive(:fetch_time_zone)

      expect(build(:event_location)).to be_valid
    end
  end

  describe ".venue_category?" do
    it "returns true for known venue keywords" do
      expect(described_class.venue_category?("Community Center Hall")).to eq(true)
      expect(described_class.venue_category?("Random Thing")).to eq(false)
    end
  end

  describe "infer_location_type callback" do
    it "infers location_type from business_name when blank" do
      allow_any_instance_of(EventLocation).to receive(:geocode_with_fallback)
      allow_any_instance_of(EventLocation).to receive(:fetch_time_zone)

      loc = build(:event_location, location_type: nil, business_name: "Sunrise Community Center")
      loc.valid?
      expect(loc.location_type).to eq("Community Center")
    end
  end
end
