
# frozen_string_literal: true

FactoryBot.define do
  factory :amigo_detail do
    association :amigo
    personal_bio { nil }
  end
end
