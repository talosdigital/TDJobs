require 'rails_helper'
require 'faker'

RSpec.describe JobService do
  before :all do
    @service = JobService.instance
  end

  describe '.search' do
    context 'when query has invalid format' do
      it 'should raise a JSONError exception' do
        expect(Job).not_to receive(:order)
        expect(TDJobs::HashQuery).not_to receive(:process_hash)
        expect { @service.search("{this invalid json}") }.to raise_error JSON::JSONError
      end
    end

    context 'when query is valid' do
      it 'should return a list of jobs that meets the conditions' do
        jobs = Job.all
        expect(TDJobs::HashQuery).to receive(:job_query)
          .with(kind_of String)
          .and_return(attributes_for(:job))
        expect(Job).to receive(:order)
          .with(kind_of Symbol)
          .and_return(jobs)
        expect(TDJobs::HashQuery).to receive(:process_hash)
          .and_return(jobs)
        expect(@service.search("{}")).to eq jobs
      end
    end
  end

  describe '.paginated_search' do
    let (:job1) { build(:job) }
    let (:job2) { build(:job) }
    let (:job3) { build(:job) }
    let (:job4) { build(:job) }
    context 'when missing page attribute' do
      it 'retrieves all jobs' do
        expect(@service).to receive(:search).and_return([job1, job2, job3, job4])
        response = @service.paginated_search('{"a_valid": "query"}', nil, 2)
        expect(response[:jobs]).to eq [job1, job2, job3, job4]
        expect(response[:total_items]).to eq [job1, job2, job3, job4].length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when missing per_page attribute' do
      it 'retrieves all jobs' do
        expect(@service).to receive(:search).and_return([job1, job2, job3, job4])
        response = @service.paginated_search('{"a_valid": "query"}', 2, nil)
        expect(response[:jobs]).to eq [job1, job2, job3, job4]
        expect(response[:total_items]).to eq [job1, job2, job3, job4].length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq 1
      end
    end

    context 'when retrieving a valid first page' do
      it 'retrieves that page of jobs' do
        matched = Job.all
        expect(@service).to receive(:search).and_return(matched)
        expect(matched).to receive(:paginate).and_return(matched)
        response = @service.paginated_search('{"a_valid": "query"}', 1, 2)
        expect(response[:jobs]).to eq matched
        expect(response[:total_items]).to eq matched.length
        expect(response[:current_page]).to eq 1
        expect(response[:total_pages]).to eq (matched.count.to_f / 2.0).ceil
      end
    end
  end

  describe '.create' do
    context 'when attributes are correct' do
      it 'should create a new Job and a JobEvent' do
        expect(Job).to receive(:create!)
          .with(kind_of Hash)
          .and_return(build(:job))

        expect(JobEvent).to receive(:create)

        created_job = @service.create(name: 'JOB NAME', description: 'JOB DESCRIPTION',
                                      owner_id: 'morning')
        expect(created_job.status).to eq 'CREATED'
      end
    end

    context 'when providing a valid due date' do
      it 'should create the Job' do
        expect(JobEvent).to receive(:create)
          .with(kind_of Hash)
          .and_return(create(:job_event))
        expect do
          attributes = attributes_for(:job)
          job = @service.create(attributes)
          expect(job.status).to eq :CREATED.to_s
          expect(job.due_date.class).to eq(attributes[:due_date].class)
        end.not_to raise_error Exception
      end
    end
  end

  describe '.update' do
    context 'when Job is not closed' do
      let(:job) { build :job }
      it 'should update the Job and create a Job Event' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).to receive(:update).with(any_args) do |_id, attrs|
          job_updated = job.clone
          attrs.each do |key, value|
            job_updated[key] = value
          end
          job_updated
        end
        expect(JobEvent).to receive(:create)

        updated_job = @service.update(1, name: 'NEW JOB NAME')
        expect(updated_job.status).to eq 'CREATED'
        expect(updated_job.name).to eq 'NEW JOB NAME'
      end
    end

    context 'when the Job is closed' do
      let(:job) { build :job, status: :CLOSED }
      it 'should raise error' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).not_to receive(:update)
        expect(JobEvent).not_to receive(:create)
        expect { @service.update(1, name: 'NEW JOB NAME') }.to raise_error TDJobs::InvalidStatus
      end
    end

    context 'when setting a valid due date' do
      let(:existent_job) { create(:job, status: :CREATED) }
      it 'should update the job' do
        expect(Job).to receive(:find)
          .with(kind_of Integer)
          .and_return(existent_job)
        expect(JobEvent).to receive(:create)
          .with(kind_of Hash)
          .and_return(build(:job_event))
        expect do
          attributes = { due_date: existent_job.start_date.prev_day }
          job = @service.update(existent_job.id, attributes)
          expect(job.due_date).to eq attributes[:due_date]
        end.not_to raise_error Exception
      end
    end
  end

  describe '.deactivate' do
    context 'when Job is active' do
      let(:job) { build :job, status: :ACTIVE }
      it 'should deactivate the Job and create a JobEvent' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).to receive(:update).with(any_args) do |_id, attrs|
          job_updated = job.clone
          attrs.each do |key, value|
            job_updated[key] = value
          end
          job_updated
        end

        expect(JobEvent).to receive(:create)
        deactivated_job = @service.deactivate(1)
        expect(deactivated_job.status).to eq 'INACTIVE'
      end
    end

    context 'when Job is inactive' do
      let(:job) { build :job, status: :INACTIVE }
      it 'should raise error' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).not_to receive(:update)
        expect(JobEvent).not_to receive(:create)
        expect { @service.deactivate(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.close' do
    context 'when Job is not closed' do
      let(:job) { build :job, status: :ACTIVE }
      it 'should close the Job and create a JobEvent' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).to receive(:update).with(any_args) do |_id, attrs|
          job_updated = job.clone
          attrs.each do |key, value|
            job_updated[key] = value
          end
          job_updated
        end

        expect(JobEvent).to receive(:create)

        deactivated_job = @service.close(1)
        expect(deactivated_job.status).to eq 'CLOSED'
      end
    end

    context 'when job is successfully closed' do
      let(:job) { build(:active_job) }
      let(:closed) { build(:closed_job) }
      it 'modifies the closed_date field to current date' do
        expect(Job).to receive(:find).with(kind_of Fixnum).and_return(job)
        expect(Job).to receive(:update).with(kind_of(Fixnum), kind_of(Hash)).and_return(closed)
        expect(JobEvent).to receive(:create)
        expect do
          closed_job = @service.close 0
          expect(closed_job.closed_date).to eq closed.closed_date
        end.not_to raise_error Exception
      end
    end

    context 'when Job is closed' do
      let(:job) { build :job, status: :CLOSED }
      it 'should raise error' do
        expect(Job).to receive(:find).and_return(job)
        expect(Job).not_to receive(:update)
        expect(JobEvent).not_to receive(:create)
        expect { @service.close(1) }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.start' do
    context 'when job is closed' do
      let(:job) { build(:closed_job) }
      let(:started) { build(:started_job) }
      it 'starts the job' do
        expect(Job).to receive(:find).with(kind_of Fixnum).and_return(job)
        expect(Job).to receive(:update).with(kind_of(Fixnum), kind_of(Hash)).and_return(started)
        expect(JobEvent).to receive(:create)
        expect do
          started_job = @service.start 0
          expect(started_job.status.to_sym).to eq :STARTED
        end.not_to raise_error Exception
      end
    end

    context 'when job is successfully started' do
      let(:job) { build(:closed_job) }
      let(:started) { build(:started_job) }
      it 'modifies the start_date field to current date' do
        expect(Job).to receive(:find).with(kind_of Fixnum).and_return(job)
        expect(Job).to receive(:update).with(kind_of(Fixnum), kind_of(Hash)).and_return(started)
        expect(JobEvent).to receive(:create)
        expect do
          started_job = @service.start 0
          expect(started_job.start_date).to eq started.start_date
        end.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be started' do
      it 'raises an InvalidStatus exception' do
        expect(Job).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(build :job, status: :CREATED)
        expect(JobEvent).not_to receive(:create)
        expect { @service.start 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end

  describe '.finish' do
    context 'when job is started' do
      let(:job) { build(:started_job) }
      let(:finished) { build(:finished_job) }
      it 'finishes the job' do
        expect(Job).to receive(:find).with(kind_of Fixnum).and_return(job)
        expect(Job).to receive(:update).with(kind_of(Fixnum), kind_of(Hash)).and_return(finished)
        expect(JobEvent).to receive(:create)
        expect do
          finished_job = @service.finish 0
          expect(finished_job.status.to_sym).to eq :FINISHED
        end.not_to raise_error Exception
      end
    end

    context 'when job is successfully finished' do
      let(:job) { build(:started_job) }
      let(:finished) { build(:finished_job) }
      it 'modifies the finish_date field to current date' do
        expect(Job).to receive(:find).with(kind_of Fixnum).and_return(job)
        expect(Job).to receive(:update).with(kind_of(Fixnum), kind_of(Hash)).and_return(finished)
        expect(JobEvent).to receive(:create)
        expect do
          finished_job = @service.finish 0
          expect(finished_job.finish_date).to eq finished.finish_date
        end.not_to raise_error Exception
      end
    end

    context 'when the status indicates it can\'t be finished' do
      it 'raises an InvalidStatus exception' do
        expect(Job).to receive(:find)
          .with(kind_of Fixnum)
          .and_return(build :job, status: :CREATED)
        expect(JobEvent).not_to receive(:create)
        expect { @service.finish 0 }.to raise_error TDJobs::InvalidStatus
      end
    end
  end
end
