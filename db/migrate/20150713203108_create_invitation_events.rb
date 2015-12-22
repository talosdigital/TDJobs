class CreateInvitationEvents < ActiveRecord::Migration
  def change
    create_table :invitation_events do |t|
      t.references :invitation, index: true, foreign_key: true
      t.string :status
      t.string :description

      t.timestamps null: false
    end
  end
end
