require 'rails_helper'

RSpec.describe OfferRecord, type: :model do
  it 'should have a valid factory' do
    expect(build :offer_record).to be_valid
  end

  context 'when the offer does not exist' do
    it 'should be invalid' do
      expect(build :offer_record, offer: nil).not_to be_valid
    end
  end

  context 'when type is not valid' do
    it 'should be invalid' do
      expect(build :offer_record, record_type: :ERROR).not_to be_valid
    end
  end

  context 'when the type is not present' do
    it 'should be invalid' do
      expect(build :offer_record, record_type: nil).not_to be_valid
    end
  end
end
