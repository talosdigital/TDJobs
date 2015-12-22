require 'rails_helper'

RSpec.describe OfferInvitation, type: :model do
  it 'has a valid factory' do
    expect(build(:offer_invitation)).to be_valid
  end

  it 'is invalid without offer' do
    expect(build(:offer_invitation, offer: nil)).not_to be_valid
  end

  it 'is invalid without invitation' do
    expect(build(:offer_invitation, invitation: nil)).not_to be_valid
  end
end
