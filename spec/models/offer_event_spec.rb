require 'rails_helper'

RSpec.describe OfferEvent, type: :model do
  it 'has a valid factory' do
    expect(build(:offer_event)).to be_valid
  end

  it 'is invalid without status' do
    expect(build(:offer_event, status: nil)).not_to be_valid
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:offer_event, status: :HACKED)).not_to be_valid
    end
  end

  it 'is invalid without description' do
    expect(build(:offer_event, description: nil)).not_to be_valid
  end

  it 'is invalid without created_at' do
    expect(build(:offer_event, created_at: nil)).not_to be_valid
  end
end
