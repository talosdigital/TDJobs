module TDJobs
  module V1
    module Entities
      class Job < Grape::Entity
        expose :id, documentation: { type: 'integer', desc: 'The job\'s id' }
        expose :owner_id, documentation: { type: 'string', desc: 'The job owner\'s id' }
        expose :name, documentation: { type: 'string', desc: 'The job\'s name' }
        expose :status, documentation: { type: 'string', desc: 'The job\'s current status' }
        expose :description, documentation: { type: 'string', desc: 'The job\'s description' }
        expose :start_date, documentation: { type: 'date', desc: 'The job\'s start date' }
        expose :finish_date, documentation: { type: 'date', desc: 'The job\'s finish date' }
        expose :due_date, documentation: { type: 'date', desc: 'The job\'s due date' }
        expose :invitation_only, documentation: {type: 'boolean', desc: 'Whether the job is invitation oly or not'}
        expose :metadata, documentation: { type: 'json', desc: 'The job\'s metadata' }
      end
    end
  end
end
