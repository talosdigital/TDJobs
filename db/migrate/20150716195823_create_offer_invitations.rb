class CreateOfferInvitations < ActiveRecord::Migration
  def change
    create_table :offer_invitations do |t|
      t.references :invitation, index: true, foreign_key: true
      t.references :offer, index: true, foreign_key: true
    end
  end
end
