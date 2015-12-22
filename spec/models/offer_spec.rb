require 'rails_helper'

RSpec.describe Offer, type: :model do
  it 'has a valid factory' do
    expect(build(:offer)).to be_valid
  end

  it 'is invalid without job' do
    expect(build(:offer, job: nil)).not_to be_valid
  end

  it 'is invalid without status' do
    expect(build(:offer, status: nil)).not_to be_valid
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:offer, status: :HACKED)).not_to be_valid
    end
  end

  it 'is invalid without provider_id' do
    expect(build(:offer, provider_id: nil)).not_to be_valid
  end

  context 'when the provider_id is a string' do
    it 'is valid' do
      expect(build(:offer, provider_id: "heinze")).to be_valid
    end
  end

  it 'is invalid without description' do
    expect(build(:offer, description: nil)).not_to be_valid
  end
end
