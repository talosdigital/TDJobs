class CreateJobEvents < ActiveRecord::Migration
  def change
    create_table :job_events do |t|
      t.references :job, index: true, foreign_key: true
      t.string :description
      t.string :status
      t.belongs_to :job, index: true
      t.timestamps null: false
    end
  end
end
