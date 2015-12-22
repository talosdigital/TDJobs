class AddStartDateAndFinishDateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :start_date, :date
    add_column :jobs, :finish_date, :date
  end
end
