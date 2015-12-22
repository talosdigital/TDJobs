require 'rails_helper'

RSpec.describe JobEvent, type: :model do
  it 'has a valid factory' do
    expect(build(:job_event)).to be_valid
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:job_event, status: :HACKED)).not_to be_valid
    end
  end

  it 'is invalid without an existent job' do
    expect(build(:job_event, job: nil)).not_to be_valid
  end

  it 'is invalid without a status' do
    expect(build(:job_event, status: nil)).not_to be_valid
  end
end
