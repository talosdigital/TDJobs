require 'faker'

FactoryGirl.define do
  factory :job_event do
    association :job, factory: :job
    description Faker::Lorem.sentence
    status 'ACTIVE'
  end
end
