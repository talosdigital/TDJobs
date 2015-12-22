require 'rails_helper'
require 'faker'

RSpec.describe TDJobs::V1::Jobs::Root do
  before :all do
    @headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json',
                 'Application-Secret' => TDJobs::configuration.application_secret }
  end

  describe 'GET /api/v1/jobs/search' do
    context 'when filter has an invalid format' do
      let(:params) { URI.escape("{invalidformat}") }
      it 'should response with a 400' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when query param is not present' do
      it 'should response with a 400' do
        get "/api/v1/jobs/search", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when filter is empty' do
      let(:params) { URI.escape("{}") }
      it 'should response with a 400' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when filter has an invalid modifier' do
      let(:params) { URI.escape("{\"drescription\": { \"mod\": 5 } }") }
      it 'should response with a 400' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when filter has all attributes invalid' do
      let(:params) { URI.escape("{\"no_where\": 1, \"another\": \"huehue\" }") }
      it 'should response with a 400' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when filter is valid' do
      let(:params) do
        URI.escape("{ \"owner_id\": \"llala\", \"name\": { \"like\": \"ala\" } }")
      end
      it 'should response with a 200' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 200
      end
    end

    context 'when filter matches an existent job' do
      let(:existent_job) { create(:active_job) }
      let(:params) do
        hash_params = {
          owner_id: {
            like: ""
          },
          name: {
            like: existent_job.name[0]
          },
          status: {
            in: [:CREATED, :ACTIVE, :INACTIVE]
          }
        }
        URI.escape(hash_params.to_json)
      end
      it 'should return an array with that job' do
        get "/api/v1/jobs/search?query=#{params}", {}, @headers
        expect(response.status).to eq 200
        jobs_found = JSON.parse(response.body)
        expect(jobs_found.first.to_json).to eq existent_job.to_json
      end
    end
  end

  describe 'GET /api/v1/jobs/search/pagination' do
    context 'when query param is not present' do
      it 'responds with a 400' do
        get "/api/v1/jobs/search/pagination", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when filter matches an existent job' do
      let(:existent_job) { create(:active_job) }
      let(:params) do
        hash_params = {
          owner_id: {
            like: ""
          },
          name: {
            like: existent_job.name[0]
          },
          status: {
            in: [:CREATED, :ACTIVE, :INACTIVE]
          }
        }
        URI.escape(hash_params.to_json)
      end
      it 'returns an array with that job' do
        get "/api/v1/jobs/search/pagination?query=#{params}", {}, @headers
        expect(response.status).to eq 200
        jobs_found = JSON.parse(response.body)
        expect(jobs_found['jobs'].first.to_json).to eq existent_job.to_json
      end
    end

    context 'when page has no items' do
      let(:existent_job) { create(:active_job) }
      let(:params) do
        hash_params = {
          owner_id: {
            like: ""
          },
          name: {
            like: existent_job.name[0]
          },
          status: {
            in: [:CREATED, :ACTIVE, :INACTIVE]
          }
        }
        URI.escape(hash_params.to_json)
      end
      it 'returns an empty array' do
        get "/api/v1/jobs/search/pagination?query=#{params}&page=2&per_page=1", {}, @headers
        expect(response.status).to eq 200
        jobs_found = JSON.parse(response.body)
        expect(jobs_found['jobs']).to eq []
        expect(jobs_found['total_pages']).to eq 1
        expect(jobs_found['current_page']).to eq 2
      end
    end
  end

  describe 'GET /api/v1/jobs' do
    context 'when there is no jobs' do
      it 'should return an empty array' do
        get '/api/v1/jobs', {}, @headers
        expect(response.status).to eq 200
        all_jobs = JSON.parse(response.body)
        expect(all_jobs).to be_a_kind_of Array
        expect(all_jobs).to be_empty
      end
    end

    context 'when there is one job' do
      let!(:existent_job) { create(:created_job) }
      it 'should return the array with one job' do
        get '/api/v1/jobs', {}, @headers
        expect(response.status).to eq 200
        all_jobs = JSON.parse(response.body)
        expect(all_jobs).to be_a_kind_of Array
        expect(all_jobs.length).to eq 1
        expect(all_jobs.first['id']).to eq existent_job.id
        expect(all_jobs.first['owner_id']).to eq existent_job.owner_id
        expect(all_jobs.first['name']).to eq existent_job.name
        expect(all_jobs.first['status']).to eq existent_job.status
        expect(all_jobs.first['description']).to eq existent_job.description
      end
    end
  end

  describe 'GET /api/v1/jobs/:id' do
    let(:existent_job) { create(:created_job) }
    context 'when id is valid' do
      it 'should return the job' do
        get "/api/v1/jobs/#{existent_job.id}", {}, @headers
        expect(response.status).to eq 200
        found_job = JSON.parse(response.body)
        expect(found_job).not_to be_a_kind_of Array
        expect(found_job['id']).to eq existent_job.id
        expect(found_job['owner_id']).to eq existent_job.owner_id
        expect(found_job['name']).to eq existent_job.name
        expect(found_job['status']).to eq existent_job.status
        expect(found_job['description']).to eq existent_job.description
      end
    end

    context 'when id is invalid' do
      it 'should response with a 404' do
        get '/api/v1/jobs/0', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /api/v1/jobs' do
    let(:body) { attributes_for :job }
    context 'when params are valid' do
      it 'creates the job' do
        post '/api/v1/jobs', body.to_json, @headers
        expect(response.status).to eq 201
        created_job = JSON.parse(response.body)
        expect(created_job['status']).to eq :CREATED.to_s
      end
    end

    context 'when params are invalid' do
      it 'returns a 400' do
        body[:name] = nil
        post '/api/v1/jobs', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when job has metadata' do
      it 'creates the job' do
        metadata = { age_restriction: { max: 25, min: 18 }, allowed_colors: %w(blue green) }
        body['metadata'] = metadata
        post '/api/v1/jobs', body.to_json, @headers
        expect(response.status).to eq 201
        created_job = JSON.parse(response.body)
        expect(created_job['status']).to eq :CREATED.to_s
        expect(created_job['metadata'].to_json).to eq metadata.to_json
      end
    end

    context 'when job has a past due date' do
      it 'should respond with a 400' do
        body[:due_date] = Date.today - Faker::Number.between(1, 365)
        post '/api/v1/jobs', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when job has a valid due date' do
      it 'should return the created job' do
        body[:due_date] = Date.today.next_month
        body[:start_date] = Date.today.next_month.next_day
        body[:finish_date] = Date.today.next_month.next_month
        post '/api/v1/jobs', body.to_json, @headers
        expect(response.status).to eq 201
        created_job = JSON.parse(response.body)
        expect(created_job['status']).to eq :CREATED.to_s
        new_date = Date.parse(created_job['due_date'])
        expect(new_date.strftime("%d-%m-%Y")).to eq body[:due_date].strftime("%d-%m-%Y")
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id' do
    let(:existent_job) { create(:job) }
    let(:body) do
      { name: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph }
    end
    context 'when the id and params are valid' do
      it 'updates the job' do
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 200
        updated_job = JSON.parse(response.body)
        expect(updated_job['name']).to eq body[:name]
        expect(updated_job['description']).to eq body[:description]
      end
    end

    context 'when the id is invalid' do
      it 'returns a 404' do
        put '/api/v1/jobs/0', body.to_json, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when params are not valid' do
      it 'returns a 400' do
        body[:name] = nil
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the params are not present' do
      it 'doesn\'t modify the job' do
        put "/api/v1/jobs/#{existent_job.id}", {}, @headers
        expect(response.status).to eq 200
        unmodified_job = JSON.parse(response.body)
        expect(unmodified_job['id']).to eq existent_job.id
        expect(unmodified_job['status']).to eq existent_job.status
        expect(unmodified_job['name']).to eq existent_job.name
        expect(unmodified_job['description']).to eq existent_job.description
        expect(unmodified_job['owner_id']).to eq existent_job.owner_id
      end
    end

    context 'when modifying metadata to a job' do
      it 'updates the job' do
        metadata = { age_restriction: { max: 25, min: 18 }, allowed_colors: %w(blue green) }
        body = { metadata: metadata }
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 200
        updated_job = JSON.parse(response.body)
        expect(updated_job['metadata'].to_json).to eq metadata.to_json
      end
    end

    context 'when modifying a closed job' do
      let(:closed_job) { create(:closed_job) }
      it 'raises a 400' do
        put "/api/v1/jobs/#{closed_job.id}", body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when due date is in the past' do
      it 'should response with a 400' do
        body[:due_date] = Date.today - Faker::Number.between(1, 365)
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when due_date is valid and on or before start_date' do
      it 'should return the updated job' do
        body[:due_date] = existent_job.finish_date - 5
        body[:start_date] = existent_job.finish_date - 3
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 200
        updated_job = JSON.parse(response.body)
        new_date = Date.parse(updated_job['due_date'])
        expect(new_date.strftime("%d-%m-%Y")).to eq body[:due_date].strftime("%d-%m-%Y")
      end
    end

    context 'when modifying start_date' do
      it 'updates the job and returns 200' do
        body[:start_date] = existent_job.start_date.next_day
        body[:finish_date] = existent_job.start_date.next_day
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 200
        updated_job = JSON.parse(response.body)
        new_start_date = Date.parse(updated_job['start_date'])
        expect(new_start_date).not_to eq existent_job.start_date
      end
    end

    context 'when modifying finish_date' do
      it 'updates the job and returns 200' do
        body[:finish_date] = existent_job.finish_date.next_day
        put "/api/v1/jobs/#{existent_job.id}", body.to_json, @headers
        expect(response.status).to eq 200
        updated_job = JSON.parse(response.body)
        new_finish_date = Date.parse(updated_job['finish_date'])
        expect(new_finish_date).not_to eq existent_job.finish_date
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id/deactivate' do
    context 'when the id is valid and the job can be deactivated' do
      let(:existent_job) { create(:active_job) }
      it 'deactivates the job' do
        put "/api/v1/jobs/#{existent_job.id}/deactivate", {}, @headers
        expect(response.status).to eq 200
        deactivated_job = JSON.parse(response.body)
        expect(deactivated_job['status']).to eq :INACTIVE.to_s
      end
    end

    context 'when the id is invalid' do
      it 'returns 404' do
        put '/api/v1/jobs/0/deactivate', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the job can\'t be deactivated' do
      let(:existent_job) { create(:inactive_job) }
      it 'returns 400' do
        put "/api/v1/jobs/#{existent_job.id}/deactivate", {}, @headers
        expect(response.status). to eq 400
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id/activate' do
    context 'when the id is valid and the job can be activated' do
      let(:existent_job) { create(:inactive_job) }
      it 'activates the job' do
        put "/api/v1/jobs/#{existent_job.id}/activate", {}, @headers
        expect(response.status).to eq 200
        activated_job = JSON.parse(response.body)
        expect(activated_job['status']).to eq :ACTIVE.to_s
      end
    end

    context 'when the id is invalid' do
      it 'returns 404' do
        put '/api/v1/jobs/0/activate', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the job can\'t be activated' do
      let(:existent_job) { create(:active_job) }
      it 'returns 400' do
        put "/api/v1/jobs/#{existent_job.id}/activate", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id/close' do
    context 'when the id is valid and the job can be closed' do
      let(:existent_job) { create(:inactive_job) }
      it 'closes the job' do
        put "/api/v1/jobs/#{existent_job.id}/close", {}, @headers
        expect(response.status).to eq 200
        closed_job = JSON.parse(response.body)
        expect(closed_job['status']).to eq :CLOSED.to_s
      end
    end

    context 'when the id is invalid' do
      it 'returns 404' do
        put '/api/v1/jobs/0/close', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the job can\'t be closed' do
      let(:existent_job) { create(:closed_job) }
      it 'returns 400' do
        put "/api/v1/jobs/#{existent_job.id}/close", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id/start' do
    context 'when the id is valid and the job can be started' do
      let(:existent_job) { create(:closed_job, due_date: Date.today) }
      it 'starts the job' do
        put "/api/v1/jobs/#{existent_job.id}/start", {}, @headers
        expect(response.status).to eq 200
        started_job = JSON.parse(response.body)
        expect(started_job['status']).to eq :STARTED.to_s
      end
    end

    context 'when the id is invalid' do
      it 'returns 404' do
        put '/api/v1/jobs/0/start', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the job can\'t be started' do
      let(:existent_job) { create(:started_job) }
      it 'returns 400' do
        put "/api/v1/jobs/#{existent_job.id}/start", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'PUT /api/v1/jobs/:id/finish' do
    context 'when the id is valid and the job can be finished' do
      let(:existent_job) { create(:started_job, start_date: Date.today, due_date: Date.today) }
      it 'finishes the job' do
        put "/api/v1/jobs/#{existent_job.id}/finish", {}, @headers
        expect(response.status).to eq 200
        finished_job = JSON.parse(response.body)
        expect(finished_job['status']).to eq :FINISHED.to_s
      end
    end

    context 'when the id is invalid' do
      it 'returns 404' do
        put '/api/v1/jobs/0/finish', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the job can\'t be finished' do
      let(:existent_job) { create(:finished_job) }
      it 'returns 400' do
        put "/api/v1/jobs/#{existent_job.id}/finish", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end
end
