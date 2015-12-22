class AddJobToInvitation < ActiveRecord::Migration
  def change
    add_reference :invitations, :job, index: true, foreign_key: true
  end
end
