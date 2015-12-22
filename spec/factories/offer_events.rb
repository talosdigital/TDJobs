require 'faker'

FactoryGirl.define do
  factory :offer_event do
    association :offer, factory: :offer
    description Faker::Lorem.sentence
    provider_id Faker::Lorem.word
    status 'CREATED'
    created_at Faker::Time.between(2.days.ago, Time.now)
  end
end
