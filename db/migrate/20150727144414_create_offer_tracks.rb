class CreateOfferTracks < ActiveRecord::Migration
  def change
    create_table :offer_tracks do |t|
      t.references :offer, index: true, foreign_key: true
      t.string :track_type
      t.string :reason

      t.timestamps null: false
    end
  end
end
