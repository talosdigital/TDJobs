class ChangeOwnerIdFormatInJobs < ActiveRecord::Migration
  def change
    change_column :jobs, :owner_id, :string
  end
end
