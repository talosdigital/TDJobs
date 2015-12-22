class RenameOfferTracksToOfferRecords < ActiveRecord::Migration
  def change
    rename_table :offer_tracks, :offer_records
  end
end
