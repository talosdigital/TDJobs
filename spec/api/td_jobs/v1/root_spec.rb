require 'rails_helper'
require 'faker'

RSpec.describe TDJobs::V1::Root do
  before :all do
    @headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
  end

  describe 'helpers.valid_token?' do
    context 'when a request doesn\'t include the secret header' do
      it 'should response with a 401' do
        get '/api/v1/invitations', {}, @headers
        expect(response.status).to eq 401
      end
    end

    context 'when a request includes an invalid secret' do
      it 'should response with a 401' do
        @headers['Application-Secret'] = TDJobs::configuration.application_secret +
                                         Faker::Lorem.word
        get '/api/v1/invitations', {}, @headers
        expect(response.status).to eq 401
      end
    end

    context 'when a request includes a valid secret' do
      it 'should not response with a 401' do
        @headers['Application-Secret'] = TDJobs::configuration.application_secret
        get '/api/v1/invitations', {}, @headers
        expect(response.status).not_to eq 401
      end
    end
  end
end
