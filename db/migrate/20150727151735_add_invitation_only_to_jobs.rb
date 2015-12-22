class AddInvitationOnlyToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :invitation_only, :boolean
  end
end
