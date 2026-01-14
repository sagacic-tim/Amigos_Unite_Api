# test/factories/amigo_details.rb
FactoryBot.define do
  factory :amigo_detail do
    association :amigo

    date_of_birth           { Date.new(1990, 1, 1) }
    member_in_good_standing { true }
    available_to_host       { false }
    willing_to_help         { true }
    willing_to_donate       { true }
    personal_bio            { "Long-time member of Amigos Unite who enjoys hosting small community gatherings and helping coordinate events." }

    # ── Trait to preserve the “spec/factories/amigo_details.rb” intent ──
    trait :no_personal_bio do
      personal_bio { nil }
    end

    # convenient alias
    trait :minimal do
      no_personal_bio
    end
  end
end
