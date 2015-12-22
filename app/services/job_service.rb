# Contains business services for Jobs.
class JobService
  extend Event::Emitter
  include Singleton

  emit! :job_searched
  # Finds a job given a certain number of custom filters in a JSON.
  # @param query [String] string representation of the JSON containing the filters.
  # @return [Job::ActiveRecord_Relation] list of jobs that meet ALL the valid filters.
  # @raise [JSON::JSONError] if 'query' doesn't correspond to a valid JSON and can't be parsed.
  # @raise [TDJobs::InvalidQuery] if no filters were given or any is invalid. Also, if an
  #   invalid modifier was used or the metadata field is not well-formed.
  # @example Allowed search modifiers.
  #   "gt"   => Greater than.
  #   "lt"   => Less than.
  #   "geq"  => Greater or equal than.
  #   "leq"  => Less or equal than.
  #   "like" => Containing the pattern.
  #   "in"   => Value in (Array)
  # @example Searching query.
  #   {
  #     "name": {
  #       "like": "a"
  #     },
  #     "owner_id": "heinzeabc",
  #     "status": {
  #       "in": [
  #         "CREATED",
  #         "ACTIVE"
  #       ]
  #     },
  #     "metadata": {
  #       "price": {
  #         "lt": 2.25,
  #         "geq": 2.20
  #       }
  #     }
  #   }
  #
  #   A valid result for this query filters would be:
  #   [
  #     {
  #       "id": 19,
  #       "name": "Plumber half time",
  #       "description": "I need a plumber to work in my company, only half time.",
  #       "owner_id": "heinzeabc",
  #       "due_date": null,
  #       "status": "CREATED",
  #       "created_at": "2015-07-31T19:53:36.014Z",
  #       "updated_at": "2015-08-04T18:50:11.599Z",
  #       "metadata": {
  #         "work_time": 4,
  #         "required_age": 18,
  #         "cities": [
  #           "New York",
  #           "Medellín",
  #           "Toronto"
  #         ],
  #         "price": 2.25
  #       },
  #       "invitation_only": true
  #     }
  #   ]
  def search(query)
    query_hash = TDJobs::HashQuery.job_query(query)
    results = Job.order(:id)
    TDJobs::HashQuery.process_hash(results, query_hash)
  end

  # Finds jobs given a certain number of custom filters in a JSON and arranges the results according
  #   to the given pagination parameters.
  # @param query [String] string representation of the JSON containing the filters.
  # @param page [Integer] page of results to be shown.
  # @param per_page [Integer] items per page to be shown.
  # @raise (#see search)
  # @example (#see search)
  def paginated_search(query, page = nil, per_page = nil)
    matched = search(query)
    response = {}
    response[:total_items] = matched.count
    response[:current_page] = 1
    response[:total_pages] = 1
    if (page.is_a?(Integer) && per_page.is_a?(Integer))
      response[:total_pages] = (matched.count.to_f / per_page.to_f).ceil
      response[:current_page] = page
      matched = matched.paginate(page: page, per_page: per_page)
    end
    response[:jobs] = matched
    response
  end

  # Finds a job given its id.
  # @param id [Integer] the id of the job to find.
  # @return [Job] the job found with the given id.
  # @raise [ActiveRecord::RecordNotFound] if no job was found with the given id.
  def find(id)
    Job.find(id)
  end

  # Finds all existing jobs.
  # @return [Array<Job>] all existing jobs.
  def find_all
    Job.all
  end

  emit! :job_created
  # Creates a new job with the given attributes.
  # @param attributes [Hash] the properties to create a job with.
  # @option attributes [String] :description The job's description. (required)
  # @option attributes [String] :name The job's name. (required)
  # @option attributes [String] :owner_id The id of the job's owner. (required)
  # @option attributes [Date] :due_date The job's due date. (optional)
  # @option attributes [Boolean] :invitation_only Whether the job receives offers only by
  #   invitations or not. (optional)
  # @option attributes [Hash] :metadata The job's metadata. (optional)
  # @return [Job] the created job.
  # @raise [TDJobs::InvalidDate] if the specified date is in the past.
  # @raise [ActiveRecord::RecordInvalid] if the given properties are invalid.
  def create(attributes)
    attributes[:status] = :CREATED
    job = Job.create! attributes
    JobEvent.create(description: 'Job Created', status: :CREATED, job: job)
    job
  end

  emit! :job_updated
  # Updates a job with the given attributes.
  # @param id [Integer] the id of the job to be updated.
  # @param attrs [Hash] the properties to modify the job with.
  # @option attrs [String] :description The new job's description.
  # @option attrs [String] :name The new job's name.
  # @option attrs [Date] :start_date The new job's start date.
  # @option attrs [Date] :finish_date The new job's finish date.
  # @option attrs [Date] :due_date The new job's due date.
  # @option attrs [Hash] :metadata The new job's metadata.
  # @return [Job] the updated job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidDate] if the specified date is in the past.
  # @raise [ActiveRecord::RecordInvalid] if the given properties are invalid.
  # @raise [TDJobs::InvalidStatus] if the given job is closed. (i.e. can't be updated)'
  def update(id, attrs)
    job = Job.find id
    if ([:CREATED, :ACTIVE, :INACTIVE].include?(job.status.to_sym))
      attrs.delete(:status)
      attrs.delete(:owner_id)
      job = update_job(id, attrs)
      JobEvent.create(description: 'Job Updated', status: job.status, job: job)
      return job
    else
      raise TDJobs::InvalidStatus, "Can't update a closed job"
    end
  end

  emit! :job_deactivated
  # Deactivates the given job.
  # @param id [Integer] the id of the job to be deactivated.
  # @return [Job] the deactivated job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the given job can't be deactivated.
  def deactivate(id)
    job = Job.find id
    if (job.status.to_sym == :ACTIVE)
      job = update_job(id, status: :INACTIVE)
      JobEvent.create(description: 'Job Deactivated', status: job.status, job: job)
      return job
    else
      raise TDJobs::InvalidStatus, "Can't deactivate Job, Job is: " + job.status
    end
  end

  emit! :job_activated
  # Activates the given job.
  # @param id [Integer] the id of the job to be activated.
  # @return [Job] the activated job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the given job can't be activated.
  def activate(id)
    job = Job.find id
    if ([:INACTIVE, :CREATED].include?(job.status.to_sym))
      job = update_job(id, status: :ACTIVE)
      JobEvent.create(description: 'Job Activated', status: job.status, job: job)
      return job
    else
      raise TDJobs::InvalidStatus, "Can't activate Job, Job is: " + job.status
    end
  end

  emit! :job_closed
  # Closes the given job.
  # @param id [Integer] the id of the job to be closed.
  # @return [Job] the closed job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the given job can't be closed.
  def close(id)
    job = Job.find id
    if ([:CREATED, :ACTIVE, :INACTIVE].include?(job.status.to_sym))
      job = update_job(id, status: :CLOSED, closed_date: DateTime.now)
      JobEvent.create(description: 'Job Closed', status: job.status, job: job)
      return job
    else
      raise TDJobs::InvalidStatus, "Can't close Job, Job is: " + job.status
    end
  end

  emit! :job_started
  # Starts the given job.
  # @param id [Integer] the id of the job to be sent.
  # @return [Job] the started job
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the given job can't be started.
  def start(id)
    job = Job.find id
    if (job.status.to_sym == :CLOSED)
      job = update_job(id, status: :STARTED, start_date: DateTime.now)
      JobEvent.create(description: 'Job started', status: job.status, job: job)
      job
    else
      raise TDJobs::InvalidStatus, "Can't start Job, Job is: " + job.status
    end
  end

  emit! :job_finished
  # Finishes the given job.
  # @param id [Integer] the id of the job to be finished.
  # @return [Job] the finished job
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the given job can't be finished.
  def finish(id)
    job = Job.find id
    if (job.status.to_sym == :STARTED)
      job = update_job(id, status: :FINISHED, finish_date: DateTime.now)
      JobEvent.create(description: 'Job finished', status: job.status, job: job)
      job
    else
      raise TDJobs::InvalidStatus, "Can't finish Job, Job is: " + job.status
    end
  end

  private

  # Updates a job with the given attributes.
  # @param id [Integer] the id of the job to be updated.
  # @param attributes [Hash] the properties to modify the job with.
  # @option attributes [String] :description The new job's description.
  # @option attributes [String] :name The new job's name.
  # @option attributes [String] :owner_id The new job's owner_id.
  # @option attributes [String] :status The new job's status.
  # @option attributes [Boolean] :invitation_only Whether the job receives offers only by
  #   invitations or not.
  # @option attributes [Date] :start_date The new job's start date.
  # @option attributes [Date] :finish_date The new job's finish date.
  # @option attributes [Date] :due_date The new job's due date.
  # @option attributes [Hash] :metadata The new job's metadata.
  # @return [Job] the updated job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [ActiveRecord::RecordInvalid] if the given properties are invalid.
  def update_job(id, attributes)
    updated_job = Job.update(id, attributes)
    if updated_job.valid?
      updated_job
    else
      raise ActiveRecord::RecordInvalid, updated_job
    end
  end
end
