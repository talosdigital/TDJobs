module TDJobs
  # Raised when trying to create an Offer with a provider that doesn't match with the job's
  #   provider.
  class ProviderMismatch < Exception
  end
end
