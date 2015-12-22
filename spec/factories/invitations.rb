require 'faker'

FactoryGirl.define do
  factory :invitation, aliases: [:created_invitation] do
    association :job, factory: :job
    status :CREATED
    provider_id Faker::Lorem.word

    factory :sent_invitation do
      status :SENT
    end

    factory :withdrawn_invitation do
      status :WITHDRAWN
    end

    factory :accepted_invitation do
      status :ACCEPTED
    end

    factory :rejected_invitation do
      status :REJECTED
    end
  end
end
