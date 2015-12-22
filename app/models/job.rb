# Maps the jobs database table and validates the data.
class Job < ActiveRecord::Base
  has_many :offers
  validates :name, presence: true
  validates :description, presence: true
  validates :owner_id, presence: true
  validate :owner_id_should_be_string
  validates :status, presence: true, inclusion: {
    in: %w(CREATED ACTIVE INACTIVE CLOSED STARTED FINISHED)
  }
  validates :due_date, presence: true
  validates_datetime :due_date, on_or_after: lambda { Date.today },
                                on_or_before: :start_date
  validates :start_date, presence: true
  validates_datetime :start_date, on_or_after: lambda { Date.today }
  validates :finish_date, presence: true
  validates_datetime :finish_date, on_or_after: :start_date
  validates_datetime :closed_date, allow_nil: true, on_or_before: :due_date

  # Determines whether the job is active or not.
  # @return [Boolean] true if the job is active, false otherwise.
  def active?
    status.to_sym == :ACTIVE
  end

  # Custom validation method, checks whether the owner_id field is String or not.
  def owner_id_should_be_string
    errors.add(:owner_id, 'is not a string') unless owner_id.is_a?(String)
  end
end
