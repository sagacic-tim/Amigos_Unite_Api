# test/factories/amigos.rb
FactoryBot.define do
  # sequences used by traits
  sequence(:amigo_user_name_short) { |n| "amigo#{n}" }
  sequence(:amigo_email_test)      { |n| "amigo#{n}@example.test" }

  factory :amigo do
    sequence(:user_name) { |n| "amigo_user_#{n}" }
    sequence(:email)     { |n| "amigo#{n}@example.com" }

    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }

    # Devise virtual attributes
    password              { "Password12345!" }   # >= 10 chars (matches your Devise config)
    password_confirmation { password }

    # If role is an enum, 0 will map to the default role.
    role { 0 }

    # ── Traits to preserve the “spec/factories/amigo.rb” intent ──

    trait :static_names do
      first_name { "Test" }
      last_name  { "Amigo" }
    end

    trait :example_test_identity do
      user_name { generate(:amigo_user_name_short) }
      email     { generate(:amigo_email_test) }
      first_name { "Test" }
      last_name  { "Amigo" }
    end

    # If your model later requires phone_1, you can use this trait in specs:
    # trait :with_phone do
    #   phone_1 { "5555555555" }
    # end
  end
end
