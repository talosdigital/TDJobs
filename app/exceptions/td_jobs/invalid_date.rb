module TDJobs
  # Raised when trying to create a Job with a due date before the current day.
  class InvalidDate < Exception
  end
end
