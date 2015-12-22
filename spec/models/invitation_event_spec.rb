require 'rails_helper'

RSpec.describe InvitationEvent, type: :model do
  it 'has a valid factory' do
    expect(build(:invitation_event)).to be_valid
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:invitation_event, status: :HACKED)).not_to be_valid
    end
  end

  it 'is invalid without an existent invitation' do
    expect(build(:invitation_event, invitation: nil)).not_to be_valid
  end

  it 'is invalid without a status' do
    expect(build(:invitation_event, status: nil)).not_to be_valid
  end
end
