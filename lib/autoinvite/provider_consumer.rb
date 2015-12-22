module Autoinvite
  class ProviderConsumer
    @@configured = false
    def self.configure(url)
      @@url = url
      @@configured = true
    end

    def self.is_configured?
      @@configured
    end

    def self.invite_providers(job)
      RestClient.post(@@url, job.to_json, content_type: :json, accept: :json) do |response, _request, _result, &_block|
        if response.code == 200
          providers = JSON.parse(response)
          providers.each do |provider|
            createInvitation({ provider_id: provider, job_id: job.id })
          end
        end
      end
    end

    def self.createInvitation(invitation)
      InvitationService.instance.create_new(invitation)
    end
  end
end
