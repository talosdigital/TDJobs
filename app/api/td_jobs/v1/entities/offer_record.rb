module TDJobs
  module V1
    module Entities
      # Maps the OfferRecord model into JSON through Grape.
      class OfferRecord < Grape::Entity
        expose :record_type, documentation: { type: 'string', desc: "The offer record's type" }
        expose :reason, documentation: { type: 'string',
                                         desc: 'The offer record\'s reason for'\
                                               'returning / resending' }
        expose :metadata, documentation: { type: 'string',
                                           desc: 'The offer\'s metadata when the record was '\
                                                 'created' }
        expose :created_at, documentation: { type: 'date',
                                             desc: 'The offer\'s record creation date' }
      end
    end
  end
end
