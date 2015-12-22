require 'rails_helper'

RSpec.describe Job, type: :model do
  it 'has a valid factory' do
    expect(build(:job)).to be_valid
  end

  context 'when it doesn\'t have a status' do
    it 'is invalid' do
      expect(build(:job, status: nil)).not_to be_valid
    end
  end

  context 'when the status is not valid' do
    it 'is invalid' do
      expect(build(:job, status: :HACKED)).not_to be_valid
    end
  end

  context 'when status is :STARTED' do
    it 'is a valid job' do
      expect(build(:job, status: :STARTED)).to be_valid
    end
  end

  context 'when status is :FINISHED' do
    it 'is a valid job' do
      expect(build(:job, status: :FINISHED)).to be_valid
    end
  end

  context 'when it doesn\'t have a description' do
    it 'is invalid' do
      expect(build(:job, description: nil)).not_to be_valid
    end
  end

  context 'when it doesn\'t have an owner id' do
    it 'is invalid' do
      expect(build(:job, owner_id: nil)).not_to be_valid
    end
  end

  context 'when the owner_id is a string' do
    it 'is valid' do
      expect(build(:job, owner_id: "heinze")).to be_valid
    end
  end

  context 'when due_date is later than or on today' do
    it 'is valid' do
      expect(build(:job, due_date: Date.today + 7.days)).to be_valid
    end
  end

  context 'when due_date has already passed' do
    it 'is invalid' do
      expect(build(:job, due_date: Date.today - 7.minutes)).not_to be_valid
    end
  end

  context 'when due_date is after start_date' do
    it 'is invalid' do
      expect(build(:job, due_date: Date.today.next_day, start_date: Date.today)).not_to be_valid
    end
  end

  context 'when due_date is after finish_date' do
    it 'is invalid' do
      expect(build(:job, due_date: Date.today.next_day, finish_date: Date.today)).not_to be_valid
    end
  end

  context 'when due_date is missing' do
    it 'is invalid' do
      expect(build(:job, due_date: nil)).not_to be_valid
    end
  end

  context 'when start_date is later than or on today' do
    it 'is valid' do
      expect(build(:job, due_date: Date.today, start_date: Date.today + 7.days)).to be_valid
    end
  end

  context 'when start_date date has already passed' do
    it 'is invalid' do
      expect(build(:job, start_date: Date.today - 7.minutes)).not_to be_valid
    end
  end

  context 'when the start_date is missing' do
    it 'is invalid' do
      expect(build(:job, start_date: nil)).not_to be_valid
    end
  end

  context 'when finish_date is later than or on start_date' do
    it 'is valid' do
      expect(build(:job, start_date: Date.today + 7.days,
                         finish_date: Date.today + 7.days,
                         due_date: Date.today))
        .to be_valid
    end
  end

  context 'when finish_date is before start_date' do
    it 'is invalid' do
      expect(build(:job, start_date: Date.today, finish_date: Date.today - 7.days))
        .not_to be_valid
    end
  end

  context 'when the finish_date is missing' do
    it 'is invalid' do
      expect(build(:job, finish_date: nil)).not_to be_valid
    end
  end

  context 'when the closed_date is missing' do
    it 'is valid' do
      expect(build(:job, closed_date: nil)).to be_valid
    end
  end

  context 'when the closed_date is before due_date' do
    it 'is valid' do
      expect(build(:job, due_date: Date.today + 7.days,
                         closed_date: Date.today + 3.days)).to be_valid
    end
  end

  context 'when the closed_date is after due_date' do
    it 'is invalid' do
      expect(build(:job, due_date: Date.today + 7.days,
                         closed_date: Date.today + 14.days)).not_to be_valid
    end
  end

  context 'when the closed_date is exactly as due_date' do
    it 'is valid' do
      same_date = Date.today + 2.days
      expect(build(:job, due_date: same_date, closed_date: same_date)).to be_valid
    end
  end
end
