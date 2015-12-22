module TDJobs
  module V1
    module Entities
      # Maps the Offer model into JSON through Grape.
      class Offer < Grape::Entity
        expose :id, documentation: { type: 'integer', desc: "The offer's id" }
        expose :description, documentation: { type: 'string', desc: 'The offer\'s description' }
        expose :provider_id, documentation: { type: 'string', desc: 'The offer\'s provider id' }
        expose :status, documentation: { type: 'string', desc: 'The offer\'s status' }
        expose :metadata, documentation: { type: 'json', desc: 'The offer\'s metadata' }
        expose :invitation, unless: lambda { |offer, options| offer.invitation.nil? } do
          expose :id do |offer, options|
            offer.invitation.id
          end
          expose :status do |offer, options|
            offer.invitation.status
          end
          expose :description do |offer, options|
            offer.invitation.description
          end
        end
        expose :offer_records, using: Entities::OfferRecord,
                               as: :records,
                               documentation: { type: 'array', desc: 'The record of events' }
        expose :job, using: Entities::Job, documentation: { type: 'object',
                                                            desc: 'The job the '\
                                                                  'Offer refers to' }
      end
    end
  end
end
