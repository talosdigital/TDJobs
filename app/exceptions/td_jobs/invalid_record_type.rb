module TDJobs
  # Raised when trying to create a record with a type different to RETURNED or RESENT.
  class InvalidRecordType < Exception
  end
end
