class CreateOfferConditions < ActiveRecord::Migration
  def change
    create_table :offer_conditions do |t|
      t.references :offer, index: true, foreign_key: true
      t.string :condition
    end
  end
end
