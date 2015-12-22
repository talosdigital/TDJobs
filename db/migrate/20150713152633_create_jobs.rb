class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name
      t.text :description
      t.integer :owner_id
      t.date :due_date
      t.string :status

      t.timestamps null: false
    end
  end
end
