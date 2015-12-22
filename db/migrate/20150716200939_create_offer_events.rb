class CreateOfferEvents < ActiveRecord::Migration
  def change
    create_table :offer_events do |t|
      t.references :offer, index: true, foreign_key: true
      t.string :description
      t.integer :provider_id
      t.string :status

      t.timestamps null: false
    end
  end
end
