
# frozen_string_literal: true

FactoryBot.define do
  factory :amigo do
    sequence(:user_name) { |n| "amigo#{n}" }
    sequence(:email)     { |n| "amigo#{n}@example.test" }

    first_name { "Test" }
    last_name  { "Amigo" }

    # Devise requires a password; keep it simple and long enough
    password              { "Password12345!" }
    password_confirmation { password }

    # If your Amigo model requires phone_1, uncomment and adjust:
    # phone_1 { "5555555555" }
  end
end
