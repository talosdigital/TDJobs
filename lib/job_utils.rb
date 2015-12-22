class JobUtils
  def self.close_all_due
    Job.where("status != 'CLOSED' AND due_date <= ? ", [Time.now]).each do |job|
      job.status = :CLOSED
      job.save
    end
  end
end
