require 'faker'

FactoryGirl.define do
  factory :offer, aliases: [:created_offer] do
    association :job, factory: :job
    description Faker::Lorem.sentence
    provider_id Faker::Lorem.word
    status :CREATED
    metadata(work_until: Faker::Date.forward(23),
             address: Faker::Address.street_address,
             min_payment: Faker::Commerce.price)

    factory :active_offer do
      status :ACTIVE
    end

    factory :sent_offer do
      status :SENT
    end

    factory :resent_offer do
      status :RESENT
    end

    factory :returned_offer do
      status :RETURNED
    end

    factory :withdrawn_offer do
      status :WITHDRAWN
    end

    factory :accepted_offer do
      status :ACCEPTED
    end

    factory :rejected_offer do
      status :REJECTED
    end
  end
end
