require 'faker'

FactoryGirl.define do
  factory :offer_record do
    association :offer, factory: :offer
    record_type 'RETURNED'
    reason Faker::Lorem.sentence
    metadata(work_until: Faker::Date.forward(10),
             address: Faker::Address.street_address,
             min_payment: Faker::Commerce.price)
  end
end
