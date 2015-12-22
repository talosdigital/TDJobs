require 'rails_helper'

RSpec.describe JobUtils do
  describe '#close_all_due' do
    before do
      @due_jobs = [
        create(:job, due_date: Time.now, status: 'CREATED'),
        create(:job, due_date: Time.now, status: 'CREATED')
      ]
    end
    it 'should destroy all due jobs' do
      JobUtils.close_all_due
      @due_jobs.each do |job|
        expect(Job.find(job.id).status).to eq 'CLOSED'
      end
    end
  end
end
