module TDJobs
  # Raised when trying to create or update an Invitation, Job or Offer with a status that is not
  #   included in its valid options. Also when the status of some object doesn't allow to continue
  #   with a procedure.
  class InvalidStatus < Exception
  end
end
