class ChangeProviderIdFormatInOffers < ActiveRecord::Migration
  def change
    change_column :offers, :provider_id, :string
  end
end
