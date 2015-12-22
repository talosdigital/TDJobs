require 'faker'

FactoryGirl.define do
  factory :invitation_event do
    association :invitation, factory: :invitation
    status 'CREATED'
  end
end
