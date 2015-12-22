class AddMetadataToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :metadata, :json, default: {}, null: false
  end
end
