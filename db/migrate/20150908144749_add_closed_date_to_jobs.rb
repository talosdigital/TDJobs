class AddClosedDateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :closed_date, :date
  end
end
