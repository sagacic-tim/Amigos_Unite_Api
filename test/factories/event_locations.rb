# test/factories/event_locations.rb
FactoryBot.define do
  factory :event_location do
    business_name              { "Sunrise Café" }
    business_phone             { "+1-555-123-4567" }
    address                    { "456 Oak Avenue, Springfield, IL 62701" }
    floor                      { "1" }
    street_number              { "456" }
    street_name                { "Oak Avenue" }
    room_no                    { "" }
    apartment_suite_number     { "" }
    city_sublocality           { "Riverfront" }
    city                       { "Springfield" }
    state_province_subdivision { "Sangamon County" }
    state_province             { "Illinois" }
    state_province_short       { "IL" }
    country                    { "United States" }
    country_short              { "US" }
    postal_code                { "62701" }
    postal_code_suffix         { "5678" }
    post_box                   { "" }
    latitude                   { 39.8000 }
    longitude                  { -89.6400 }
    time_zone                  { "America/Chicago" }
    status                     { 0 } # e.g. active, assuming enum in model
    location_type              { "cafe" }
    owner_name                 { "Jordan Smith" }
    capacity_seated            { 40 }
    availability_notes         { "Available most weeknights after 6 PM." }
    has_food                   { true }
    has_drink                  { true }
    has_internet               { true }
    has_big_screen             { false }
    place_id                   { "fake-place-id-123" }
    capacity                   { 40 }
    services                   { { food: true, drink: true, internet: true } }
    location_image_attribution { "Photo by Example Photographer via Google Places." }
  end
end
