# Maps the invitations database table and validates the data.
class Invitation < ActiveRecord::Base
  has_one :offer, through: :offer_invitations
  belongs_to :job
  validates :status, presence: true, inclusion: { in: %w(CREATED SENT WITHDRAWN ACCEPTED REJECTED) }
  validates :provider_id, presence: true
  validate :provider_id_should_be_string
  validates :job, presence: true

  # Custom validation method, checks whether the owner_id field is String or not.
  def provider_id_should_be_string
    errors.add(:provider_id, 'is not a string') unless provider_id.is_a?(String)
  end
end
