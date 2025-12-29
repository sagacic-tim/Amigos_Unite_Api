
# test/factories/amigo_locations.rb
FactoryBot.define do
  factory :amigo_location do
    association :amigo

    address                  { "123 Maple Street, Apt 4B, Springfield, IL 62704" }
    floor                    { "4" }
    street_number            { "123" }
    street_name              { "Maple Street" }
    room_no                  { "" }
    apartment_suite_number   { "4B" }
    city_sublocality         { "Downtown" }
    city                     { "Springfield" }
    state_province_subdivision { "Sangamon County" }
    state_province           { "Illinois" }
    state_province_short     { "IL" }
    country                  { "United States" }
    country_short            { "US" }
    postal_code              { "62704" }
    postal_code_suffix       { "1234" }
    post_box                 { "" }
    latitude                 { 39.7817 }
    longitude                { -89.6501 }
    time_zone                { "America/Chicago" }
  end
end
