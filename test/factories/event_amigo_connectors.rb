# test/factories/event_amigo_connectors.rb
FactoryBot.define do
  factory :event_amigo_connector do
    association :amigo
    association :event

    # Let defaults handle role/status unless you know the enum mappings.
    role   { 0 }
    status { 0 }
  end
end
