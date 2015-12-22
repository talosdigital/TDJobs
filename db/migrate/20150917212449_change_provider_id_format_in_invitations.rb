class ChangeProviderIdFormatInInvitations < ActiveRecord::Migration
  def change
    change_column :invitations, :provider_id, :string
  end
end
