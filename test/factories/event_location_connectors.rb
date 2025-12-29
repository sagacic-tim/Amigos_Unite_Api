# test/factories/event_location_connectors.rb
FactoryBot.define do
  factory :event_location_connector do
    association :event
    association :event_location

    status     { 0 }
    is_primary { true }
  end
end

