class DropOfferConditions < ActiveRecord::Migration
  def change
    drop_table :offer_conditions
  end
end
