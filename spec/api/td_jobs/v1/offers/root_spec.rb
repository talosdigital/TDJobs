require 'rails_helper'

RSpec.describe TDJobs::V1::Offers::Root do
  before :all do
    @headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json',
                 'Application-Secret' => TDJobs::configuration.application_secret }
  end

  describe 'GET /api/v1/offers' do
    let(:existent_offer) { build(:created_offer) }
    context 'when there is no offers' do
      it 'should return an empty array' do
        get '/api/v1/offers', {}, @headers
        expect(response.status).to eq 200
        all_offers = JSON.parse(response.body)
        expect(all_offers).to be_a_kind_of Array
        expect(all_offers).to be_empty
      end
    end

    context 'when there is one offer' do
      it 'should return the array with one offer' do
        existent_offer.save
        get '/api/v1/offers', {}, @headers
        expect(response.status).to eq 200
        all_offers = JSON.parse(response.body)
        expect(all_offers).to be_a_kind_of Array
        expect(all_offers.length).to eq 1
        expect(all_offers.first['id']).to eq existent_offer.id
        expect(all_offers.first['job']['id']).to eq existent_offer.job_id
        expect(all_offers.first['provider_id']).to eq existent_offer.provider_id
        expect(all_offers.first['status']).to eq existent_offer.status
        expect(all_offers.first['description']).to eq existent_offer.description
      end
    end

    context 'when the job filter is present' do
      let(:params) { URI.escape("{}") }
      it 'calls :find_by_with_job_filter method' do
        expect(OfferService.instance).not_to receive(:find_by)
        expect(OfferService.instance).to receive(:find_by_with_job_filter).and_return([])
        get "/api/v1/offers?job_filter=#{params}", {}, @headers
        expect(response.status).to eq 200
        expect(response.body).to eq [].to_json
      end
    end

    context 'when the job filter is not present' do
      it 'calls :find_by method' do
        expect(OfferService.instance).not_to receive(:find_by_with_job_filter)
        expect(OfferService.instance).to receive(:find_by).and_return([])
        get "/api/v1/offers", {}, @headers
        expect(response.status).to eq 200
        expect(response.body).to eq [].to_json
      end
    end
  end

  describe 'GET /api/v1/offers/pagination' do
    context 'when no param is present' do
      it 'responds with a 200 and all offers' do
        get "/api/v1/offers/pagination", {}, @headers
        expect(response.status).to eq 200
        parsed = JSON.parse(response.body)
        expect(parsed['current_page']).to eq 1
        expect(parsed['total_pages']).to eq 1
        expect(parsed['offers'].to_json).to eq Offer.all.to_json
      end
    end

    context 'when :paginated_find raises a JSONError' do
      it 'returns a 400' do
        expect(OfferService.instance).to receive(:paginated_find).and_raise JSON::JSONError
        get "/api/v1/offers/pagination", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when :paginated_find raises an InvalidQuery' do
      it 'returns a 400' do
        expect(OfferService.instance).to receive(:paginated_find).and_raise TDJobs::InvalidQuery
        get "/api/v1/offers/pagination", {}, @headers
        expect(response.status).to eq 400
      end
    end
  end

  describe 'GET /api/v1/offers/:id' do
    let(:existent_offer) { build(:created_offer) }
    context 'when id is valid' do
      it 'should return the offer with its records' do
        existent_offer.save
        get "/api/v1/offers/#{existent_offer.id}", {}, @headers
        expect(response.status).to eq 200
        found_offer = JSON.parse(response.body)
        expect(found_offer).not_to be_a_kind_of Array
        expect(found_offer['id']).to eq existent_offer.id
        expect(found_offer['job']['id']).to eq existent_offer.job_id
        expect(found_offer['provider_id']).to eq existent_offer.provider_id
        expect(found_offer['status']).to eq existent_offer.status
        expect(found_offer['description']).to eq existent_offer.description
        expect(found_offer['records']).to be_a_kind_of Array
      end
    end

    context 'when id is invalid' do
      it 'should raise a RecordNotFound exception' do
        get '/api/v1/offers/0', {}, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the offer has an associated invitation' do
      let(:existent_invitation) { build(:invitation) }
      it 'returns an extra field with the invitation information' do
        existent_offer.invitation = existent_invitation
        expect(OfferService.instance).to receive(:find).and_return(existent_offer)
        get '/api/v1/offers/1', {}, @headers
        found_offer = JSON.parse(response.body)
        expect(found_offer['invitation']).not_to eq nil
        expect(found_offer['invitation']['status']).to eq existent_invitation.status
        expect(found_offer['invitation']['description']).to eq existent_invitation.description
      end
    end

    context 'when the offer doesn\'t have an associated invitation' do
      it 'returns the response without an \'invitation\' field' do
        existent_offer.invitation = nil
        expect(OfferService.instance).to receive(:find).and_return(existent_offer)
        get '/api/v1/offers/1', {}, @headers
        found_offer = JSON.parse(response.body)
        expect(found_offer['invitation']).to eq nil
      end
    end
  end

  describe 'POST /api/v1/offers' do
    let(:existent_job) { create(:active_job) }
    let(:body) do
      { job_id: existent_job.id,
        description: Faker::Lorem.paragraph,
        provider_id: Faker::Lorem.word,
        metadata: { age_restriction: { max: 35, min: 18 }, allowed_colors: %w(blue green red),
                    conditions: ['only for overage', 'worker must have any smartphone'] } }
    end
    context 'when attributes are present and valid' do
      it 'should create the offer' do
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
      end
    end

    context 'when attributes are incomplete' do
      it 'should not create the offer' do
        body = { job_id: nil }
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the given job doesn\'t exist' do
      it 'should raise a RecordNotFound exception' do
        body[:job_id] = 0
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 404
      end
    end

    context 'when the given job is not active' do
      let(:nonactive_job) { create(:closed_job) }
      it 'shoud raise a InvalidStatus exception' do
        body[:job_id] = nonactive_job.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when offer has metadata' do
      let(:metadata) { body[:metadata] }
      it 'should create the offer' do
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
        expect(created_offer['metadata'].to_json).to eq metadata.to_json
      end
    end

    context 'when offer doesn\'t have metadata' do
      it 'should create the offer' do
        body[:metadata] = nil
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
        expect(created_offer['metadata']).to eq({})
      end
    end

    context 'when offer is based on a sent invitation' do
      let(:existent_invitation) do
        create(:invitation, status: :ACCEPTED, job_id: existent_job.id, provider_id: body[:provider_id])
      end
      it 'should return the created offer' do
        body[:invitation_id] = existent_invitation.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
      end
    end

    context 'when offer is based on a non-sent invitation' do
      let(:existent_invitation) do
        create(:invitation, status: :REJECTED, job_id: existent_job.id, provider_id: body[:provider_id])
      end
      it 'should return a 400' do
        body[:invitation_id] = existent_invitation.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when providers don\'t match' do
      let(:existent_invitation) do
        create(:invitation, status: :SENT, job_id: existent_job.id,
                           provider_id: body[:provider_id] + Faker::Lorem.word)
      end
      it 'should return a 400' do
        body[:invitation_id] = existent_invitation.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when providers match' do
      let(:existent_invitation) do
        create(:invitation,
               job_id: existent_job.id,
               provider_id: body[:provider_id],
               status: :ACCEPTED)
      end
      it 'should return the created offer' do
        body[:invitation_id] = existent_invitation.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
      end
    end

    context 'when the job is invitation_only but without an invitation' do
      let(:invitation_only_job) { create(:job, status: :ACTIVE, invitation_only: true) }
      it 'should return a 400' do
        body[:job_id] = invitation_only_job.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the job is invitation_only' do
      let(:invitation_only_job) { create(:active_job, invitation_only: true) }
      let(:existent_invitation) do
        create(:invitation,
               job_id: invitation_only_job.id,
               provider_id: body[:provider_id],
               status: :ACCEPTED)
      end
      it 'should return the created offer' do
        body[:job_id] = invitation_only_job.id
        body[:invitation_id] = existent_invitation.id
        post '/api/v1/offers', body.to_json, @headers
        expect(response.status).to eq 201
        created_offer = JSON.parse(response.body)
        expect(created_offer['status']).to eq :CREATED.to_s
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/send' do
    context 'when the offer is sendable' do
      let(:existent_offer) { create(:created_offer) }
      it 'should return the sent offer' do
        put "/api/v1/offers/#{existent_offer.id}/send", {}, @headers
        expect(response.status).to eq 200
        sent_offer = JSON.parse(response.body)
        expect(sent_offer['status']).to eq :SENT.to_s
      end
    end

    context 'when the offer is non-sendable' do
      let(:existent_offer) { create(:sent_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/send", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/send', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/resend' do
    context 'when the offer is resendable' do
      let(:existent_offer) { create(:returned_offer) }
      it 'should return the resent offer and create an Offer Record' do
        put "/api/v1/offers/#{existent_offer.id}/resend", {}, @headers
        expect(response.status).to eq 200
        resent_offer = JSON.parse(response.body)
        expect(OfferRecord.find_by(offer_id: existent_offer.id).record_type).to eq :RESENT.to_s
        expect(resent_offer['status']).to eq :RESENT.to_s
      end
    end

    context 'when the offer is non-resendable' do
      let(:existent_offer) { create(:resent_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/resend", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/resend', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/withdraw' do
    context 'when the offer is withdrawable' do
      let(:existent_offer) { create(:sent_offer) }
      it 'should return the withdrawn offer' do
        put "/api/v1/offers/#{existent_offer.id}/withdraw", {}, @headers
        expect(response.status).to eq 200
        withdrawn_offer = JSON.parse(response.body)
        expect(withdrawn_offer['status']).to eq :WITHDRAWN.to_s
      end
    end

    context 'when the offer is non-withdrawable' do
      let(:existent_offer) { create(:withdrawn_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/withdraw", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/withdraw', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/return' do
    context 'when the offer is returnable' do
      let(:existent_offer) { create(:sent_offer) }
      it 'should return the returned offer and create an OfferRecord' do
        put "/api/v1/offers/#{existent_offer.id}/return", {}, @headers
        expect(response.status).to eq 200
        returned_offer = JSON.parse(response.body)
        expect(OfferRecord.find_by(offer_id: existent_offer.id).record_type).to eq :RETURNED.to_s
        expect(returned_offer['status']).to eq :RETURNED.to_s
      end
    end

    context 'when the offer is non-returnable' do
      let(:existent_offer) { create(:returned_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/return", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/return', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/reject' do
    context 'when the offer is rejectable' do
      let(:existent_offer) { create(:resent_offer) }
      it 'should return the rejected offer' do
        put "/api/v1/offers/#{existent_offer.id}/reject", {}, @headers
        expect(response.status).to eq 200
        rejected_offer = JSON.parse(response.body)
        expect(rejected_offer['status']).to eq :REJECTED.to_s
      end
    end

    context 'when the offer is non-rejectable' do
      let(:existent_offer) { create(:rejected_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/reject", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/reject', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /api/v1/offers/:id/accept' do
    context 'when the offer is acceptable' do
      let(:existent_offer) { create(:sent_offer) }
      it 'should return the accepted offer' do
        put "/api/v1/offers/#{existent_offer.id}/accept", {}, @headers
        expect(response.status).to eq 200
        accepted_offer = JSON.parse(response.body)
        expect(accepted_offer['status']).to eq :ACCEPTED.to_s
      end
    end

    context 'when the offer is non-acceptable' do
      let(:existent_offer) { create(:accepted_offer) }
      it 'should response with a 400' do
        put "/api/v1/offers/#{existent_offer.id}/accept", {}, @headers
        expect(response.status).to eq 400
      end
    end

    context 'when the offer doesn\'t exist' do
      it 'should response with a 404' do
        put '/api/v1/offers/0/accept', {}, @headers
        expect(response.status).to eq 404
      end
    end
  end
end
