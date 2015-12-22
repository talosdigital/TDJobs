require 'rails_helper'

RSpec.describe Autoinvite::ProviderConsumer do
  describe 'invite_providers' do
    context '' do
      let(:job) { build :job, status: :SENT }
      it 'should create invites' do
        expect(RestClient).to receive(:post).with(any_args) do |_url, _job_as_json, _content_type, _accept, &block|
          response = '[1,2,3,4,5]'
          response.define_singleton_method(:code) { 200 }
          block.call(response, {}, {})
        end

        expect(Autoinvite::ProviderConsumer).to receive(:createInvitation)
          .with(kind_of(Hash))
          .exactly(5).times

        Autoinvite::ProviderConsumer.configure('dummy_url')
        Autoinvite::ProviderConsumer.invite_providers(job)
      end
    end
  end
end
