module TDJobs
  # Raised when trying to create an Offer with invitation_only flag in true but without an
  #   invitation.
  class MissingInvitation < Exception
  end
end
