class RenameColumnTrackTypeToRecordType < ActiveRecord::Migration
  def change
    rename_column :offer_records, :track_type, :record_type
  end
end
