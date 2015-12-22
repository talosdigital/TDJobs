class AddDescriptionToInvitation < ActiveRecord::Migration
  def change
    add_column :invitations, :description, :text
  end
end
