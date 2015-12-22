class AddMetadataToOfferRecords < ActiveRecord::Migration
  def change
    add_column :offer_records, :metadata, :json, default: {}, null: false
  end
end
