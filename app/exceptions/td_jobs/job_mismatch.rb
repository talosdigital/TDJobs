module TDJobs
  # Raised when trying to create an Offer with a Job that doesn't match with the 
  # invitation's Job
  class JobMismatch < Exception
  end
end