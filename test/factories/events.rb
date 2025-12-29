# test/factories/events.rb
FactoryBot.define do
  factory :event do
    association :lead_coordinator, factory: :amigo

    event_name  { "Monthly Community Gathering" }
    event_type  { "Meetup" }
    event_date  { Date.today + 7.days }
    event_time  { Time.zone.parse("19:00") }

    status      { :planning }

    event_speakers_performers { ["Guest Speaker A", "Guest Speaker B"] }
    description { "A monthly meetup to connect local Amigos and discuss upcoming projects." }
  end
end
