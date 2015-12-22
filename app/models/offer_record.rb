# Maps the offer_records database table and validates the data. An OfferRecord is created and
# persisted every time an Offer is created, returned or resent.
class OfferRecord < ActiveRecord::Base
  belongs_to :offer

  validates :offer, presence: true
  validates :record_type, presence: true, inclusion: { in: %w(CREATED RESENT RETURNED) }
end
