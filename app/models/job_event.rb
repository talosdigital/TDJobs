# Maps the job_events database table and validates the data.
class JobEvent < ActiveRecord::Base
  belongs_to :job
  validates :job, presence: true
  validates :status, presence: true, inclusion: { in: %w(CREATED ACTIVE INACTIVE CLOSED) }
end
