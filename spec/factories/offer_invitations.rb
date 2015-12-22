FactoryGirl.define do
  factory :offer_invitation do
    association :invitation, factory: :invitation
    association :offer, factory: :offer
  end
end
