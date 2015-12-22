# Maps the invitation_events database table and validates the data.
class InvitationEvent < ActiveRecord::Base
  belongs_to :invitation
  validates :invitation, presence: true
  validates :status, presence: true, inclusion: { in: %w(CREATED SENT WITHDRAWN ACCEPTED REJECTED) }
end
