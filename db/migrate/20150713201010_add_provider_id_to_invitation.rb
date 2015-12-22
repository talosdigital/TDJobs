class AddProviderIdToInvitation < ActiveRecord::Migration
  def change
    add_column :invitations, :provider_id, :integer
  end
end
