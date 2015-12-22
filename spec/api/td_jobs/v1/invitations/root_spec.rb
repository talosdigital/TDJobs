require 'rails_helper'

RSpec.describe TDJobs::V1::Invitations::Root do
  before :all do
    @headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json',
                 'Application-Secret' => TDJobs::configuration.application_secret }
  end

  describe 'GET /api/v1/invitations' do
    context 'when there is no invitations' do
      it 'should return an empty array' do
        get '/api/v1/invitations', {}, @headers
        expect(response.status).to eq 200
        all_invitations = JSON.parse(response.body)
        expect(all_invitations).to be_a_kind_of Array
        expect(all_invitations).to be_empty
      end
    end

    context 'when there is one invitation and no filters' do
      let!(:invitation) { FactoryGirl.create(:invitation) }
      it 'should return the array with one invitation' do
        get '/api/v1/invitations', {}, @headers
        expect(response.status).to eq 200
        all_invitations = JSON.parse(response.body)
        expect(all_invitations).to be_a_kind_of Array
        expect(all_invitations.length).to eq 1
        expect(all_invitations.first['id']).to eq invitation.id
        expect(all_invitations.first['job']['id']).to eq invitation.job.id
        expect(all_invitations.first['provider_id']).to eq invitation.provider_id
        expect(all_invitations.first['status']).to eq invitation.status
      end
    end

    context 'when there is two invitation and filter one' do
      let!(:invitation1) { FactoryGirl.create(:invitation) }
      let!(:invitation2) { FactoryGirl.create(:withdrawn_invitation) }
      it 'should return the array with one invitation' do
        get '/api/v1/invitations', {status: 'CREATED'}, @headers
        expect(response.status).to eq 200
        all_invitations = JSON.parse(response.body)
        expect(all_invitations).to be_a_kind_of Array
        expect(all_invitations.length).to eq 1
        expect(all_invitations.first['id']).to eq invitation1.id
        expect(all_invitations.first['job']['id']).to eq invitation1.job.id
        expect(all_invitations.first['provider_id']).to eq invitation1.provider_id
        expect(all_invitations.first['status']).to eq invitation1.status
      end
    end
  end

  describe 'GET /api/v1/invitations/pagination' do
    context 'when no param is present' do
      it 'responds with a 200 and all invitations' do
        get "/api/v1/invitations/pagination", {}, @headers
        expect(response.status).to eq 200
        parsed = JSON.parse(response.body)
        expect(parsed['current_page']).to eq 1
        expect(parsed['total_pages']).to eq 1
        expect(parsed['invitations'].to_json).to eq Invitation.all.to_json
      end
    end

    context 'when :paginated_find raises a JSONError' do
      it 'returns a 400' do
        expect(InvitationService.instance).to receive(:paginated_find).and_raise JSON::JSONError
        get "/api/v1/invitations/pagination", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when :paginated_find raises an InvalidQuery' do
      it 'returns a 400' do
        expect(InvitationService.instance).to receive(:paginated_find)
          .and_raise TDJobs::InvalidQuery
        get "/api/v1/invitations/pagination", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'GET /api/v1/invitations/:id' do
    let(:invitation) { create(:invitation) }
    context 'when id is valid' do
      it 'should return the invitation' do
        get "/api/v1/invitations/#{invitation.id}", {}, @headers
        expect(response.status).to eq 200
        found_invitation = JSON.parse(response.body)
        expect(found_invitation).not_to be_a_kind_of Array
        expect(found_invitation['id']).to eq invitation.id
        expect(found_invitation['job']['id']).to eq invitation.job.id
        expect(found_invitation['provider_id']).to eq invitation.provider_id
        expect(found_invitation['status']).to eq invitation.status
      end
    end

    context 'when id is invalid' do
      it 'should raise a RecordNotFound exception' do
        get '/api/v1/invitations/0', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /api/v1/invitations' do
    let(:invitation) { build(:invitation) }
    context 'when all attributes are present and valid' do
      let(:existent_job) { create(:active_job) }
      it 'should create the invitation' do
        body = { provider_id: invitation.provider_id, job_id: existent_job.id }
        post '/api/v1/invitations', body.to_json, @headers
        expect(response.status).to eq 201
        created_invitation = JSON.parse(response.body)
        expect(created_invitation['provider_id']).to eq invitation.provider_id
        expect(created_invitation['job']['id']).to eq existent_job.id
        expect(created_invitation['status']).to eq :CREATED.to_s
      end
    end

    context 'when provider_id is not present' do
      it 'should return a 400' do
        body = { provider_id: nil }
        post '/api/v1/invitations', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when job_id is not present' do
      it 'should return a 400' do
        body = { job_id: nil }
        post '/api/v1/invitations', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when job doesn\'t exist' do
      it 'should raise a RecordNotFound exception' do
        body = { provider_id: invitation.provider_id, job_id: 0 }
        post '/api/v1/invitations', body.to_json, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the given job is not active' do
      let(:existent_job) { create(:inactive_job) }
      it 'should raise an InvalidStatus exception' do
        body = { provider_id: invitation.provider_id, job_id: existent_job.id }
        post '/api/v1/invitations', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'PUT /api/v1/invitations/:id/send' do
    context 'when the invitation is sendable' do
      let(:invitation) { create(:created_invitation) }
      it 'returns the sent invitation' do
        put "/api/v1/invitations/#{invitation.id}/send", {}, @headers
        expect(response.status).to eq 200
        sent_invitation = JSON.parse(response.body)
        expect(sent_invitation['status']).to eq :SENT.to_s
      end
    end

    context 'when the invitation is non-sendable' do
      let(:invitation) { create(:sent_invitation) }
      it 'responses with an error status code' do
        put "/api/v1/invitations/#{invitation.id}/send", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the invitation does\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/invitations/0/send', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/invitations/:id/withdraw' do
    context 'when the invitation is withdrawable' do
      let(:invitation) { create(:created_invitation) }
      it 'returns the withdrawn invitation' do
        put "/api/v1/invitations/#{invitation.id}/withdraw", {}, @headers
        expect(response.status).to eq 200
        withdrawn_invitation = JSON.parse(response.body)
        expect(withdrawn_invitation['status']).to eq :WITHDRAWN.to_s
      end
    end

    context 'when the invitation is non-withdrawable' do
      let(:invitation) { create(:withdrawn_invitation) }
      it 'responses with an error status code' do
        put "/api/v1/invitations/#{invitation.id}/withdraw", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the invitation does\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/invitations/0/withdraw', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/invitations/:id/accept' do
    context 'when the invitation is acceptable' do
      let(:invitation) { create(:sent_invitation) }
      it 'returns the accepted invitation' do
        put "/api/v1/invitations/#{invitation.id}/accept", {}, @headers
        expect(response.status).to eq 200
        accepted_invitation = JSON.parse(response.body)
        expect(accepted_invitation['status']).to eq :ACCEPTED.to_s
      end
    end

    context 'when the invitation is non-acceptable' do
      let(:invitation) { create(:rejected_invitation) }
      it 'responses with an error status code' do
        put "/api/v1/invitations/#{invitation.id}/accept", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the invitation does\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/invitations/0/accept', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/invitations/:id/reject' do
    context 'when the invitation is rejectable' do
      let(:invitation) { create(:sent_invitation) }
      it 'returns the rejected invitation' do
        put "/api/v1/invitations/#{invitation.id}/reject", {}, @headers
        expect(response.status).to eq 200
        accepted_invitation = JSON.parse(response.body)
        expect(accepted_invitation['status']).to eq :REJECTED.to_s
      end
    end

    context 'when the invitation is non-rejectable' do
      let(:invitation) { create(:withdrawn_invitation) }
      it 'responses with an error status code' do
        put "/api/v1/invitations/#{invitation.id}/reject", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the invitation does\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/invitations/0/reject', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/invitations' do
    context 'when the invitation id is nil' do
      it 'responses with an error status code' do
        put '/api/v1/invitations/nil/withdraw', {}, @headers
        expect(response.status).to eq 400
        put '/api/v1/invitations/nil/accept', {}, @headers
        expect(response.status).to eq 400
        put '/api/v1/invitations/nil/reject', {}, @headers
        expect(response.status).to eq 400
      end
    end
  end
end
