# Maps the offer_invitations database table and validates the data.
class OfferInvitation < ActiveRecord::Base
  belongs_to :invitation
  belongs_to :offer

  validates :offer, presence: true
  validates :invitation, presence: true
end
