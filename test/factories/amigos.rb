# test/factories/amigos.rb
FactoryBot.define do
  factory :amigo do
    sequence(:user_name) { |n| "amigo_user_#{n}" }
    sequence(:email)     { |n| "amigo#{n}@example.com" }

    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }

    # Devise virtual attributes – not in schema.rb but expected by Devise
    password              { "Password123!" }
    password_confirmation { password }

    # Role enum – default 0; we’ll let the model default handle it
    role { 0 }
  end
end
