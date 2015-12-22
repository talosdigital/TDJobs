require 'rails_helper'

RSpec.describe Invitation, type: :model do
  it 'has a valid factory' do
    expect(build(:invitation)).to be_valid
  end

  context 'when it doesn\'t have a status' do
    it 'is invalid' do
      expect(build(:invitation, status: nil)).not_to be_valid
    end
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:invitation, status: :HACKED)).not_to be_valid
    end
  end

  context 'when it doesn\'t have a job' do
    it 'is invalid' do
      expect(build(:invitation, job: nil)).not_to be_valid
    end
  end

  context 'when it doesn\'t have a provider id' do
    it 'is invalid' do
      expect(build(:invitation, provider_id: nil)).not_to be_valid
    end
  end

  context 'when the provider_id is a string' do
    it 'is valid' do
      expect(build(:invitation, provider_id: "heinze")).to be_valid
    end
  end
end
