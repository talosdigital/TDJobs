# Maps the offer_events database table and validates the data.
class OfferEvent < ActiveRecord::Base
  belongs_to :offer

  validates :offer, presence: true
  validates :status, presence: true,
                     inclusion: { in: %w(CREATED SENT WITHDRAWN RETURNED RESENT ACCEPTED REJECTED) }
  validates :description, presence: true
  validates :created_at, presence: true
end
