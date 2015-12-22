# Maps the offers database table and validates the data.
class Offer < ActiveRecord::Base
  belongs_to :job
  has_one :offer_invitation
  has_one :invitation, through: :offer_invitation
  has_many :offer_records

  validates :job, presence: true
  validates :description, presence: true
  validates :provider_id, presence: true
  validate :provider_id_should_be_string

  validates :status, presence: true,
                     inclusion: { in: %w(CREATED SENT WITHDRAWN RETURNED RESENT ACCEPTED REJECTED) }

  # Custom validation method, checks whether the owner_id field is String or not.
  def provider_id_should_be_string
    errors.add(:provider_id, 'is not a string') unless provider_id.is_a?(String)
  end
end
