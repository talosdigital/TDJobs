module TDJobs
  module V1
    module Entities
      class Invitation < Grape::Entity
        expose :id, documentation: { type: 'integer', desc: "The invitation's id" }
        expose :status, documentation: { type: 'string', desc: "The invitation's status" }
        expose :provider_id, documentation: { type: 'string', desc: 'The id of the '\
                                                                     "invitation's provider" }
        expose :description, documentation: { type: 'string', desc: "The invitation's description" }
        expose :job, using: Entities::Job, documentation: { type: 'object',
                                                            desc: 'The job the '\
                                                                  'invitation refers to' }
        expose :created_at, documentation: { type: 'date', desc: "The invitation's creation date" }
      end
    end
  end
end
