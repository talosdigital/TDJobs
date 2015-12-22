class ChangeProviderIdFormatInOfferEvents < ActiveRecord::Migration
  def change
    change_column :offer_events, :provider_id, :string
  end
end
