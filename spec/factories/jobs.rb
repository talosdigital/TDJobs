require 'faker'

FactoryGirl.define do
  factory :job, aliases: [:created_job] do
    name Faker::Lorem.word
    description Faker::Lorem.sentence
    owner_id Faker::Lorem.word
    due_date Date.today.next_month
    start_date Date.today.next_month.next_day
    finish_date Date.today.next_month.next_month
    closed_date nil
    status :CREATED
    created_at Faker::Time.between(2.days.ago, Time.now)
    invitation_only false
    metadata(price: Faker::Commerce.price, address: Faker::Address.street_address,
             cities: [ Faker::Address.city, Faker::Address.city, Faker::Address.city])

    factory :active_job do
      status :ACTIVE
    end

    factory :inactive_job do
      status :INACTIVE
    end

    factory :closed_job do
      status :CLOSED
    end

    factory :started_job do
      status :STARTED
    end

    factory :finished_job do
      status :FINISHED
    end
  end
end
