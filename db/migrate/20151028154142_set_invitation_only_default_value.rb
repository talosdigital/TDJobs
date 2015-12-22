class SetInvitationOnlyDefaultValue < ActiveRecord::Migration
  def change
    change_column :jobs, :invitation_only, :boolean, default: false
  end
end
