class AddMetadataToOffer < ActiveRecord::Migration
  def change
    add_column :offers, :metadata, :json, default: {}, null: false
  end
end
