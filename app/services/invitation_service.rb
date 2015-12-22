# Contains business services for Invitations.
class InvitationService
  extend Event::Emitter
  include Singleton

  # Finds an invitation given its id.
  # @param id [Integer] the id of the invitation to find.
  # @return [Invitation] the invitation found with the given id.
  # @raise [ActiveRecord::RecordNotFound] if no invitation was found with the given id.
  def find(id)
    Invitation.find(id)
  end

  # Finds all invitations matching the parameters.
  # @param params [Hash] the parameters to search the invitations with.
  # @option params [String] :provider_id The id of the provider.
  # @option params [Integer] :job_id The id of the job the invitation is for.
  # @option params [String] :status The status of the invitation, can be a single String or an Array of Strings.
  # @option params [String] :created_at_from The lower limit for the creation date of the invitation.
  # @option params [String] :created_at_to The upper limit for the creation date of the invitation.
  # @return [Array<Invitation>] all matching invitations.
  def find_by(params)
    invitations = Invitation.order(:id)
    invitations = invitations.where("provider_id = ?", params[:provider_id]) if params[:provider_id]
    invitations = invitations.where("job_id = ?", params[:job_id]) if params[:job_id]
    if params[:status]
      if params[:status].kind_of? Array
        invitations = invitations.where("status in (?)", params[:status])
      else
        invitations = invitations.where("status = ?", params[:status])
      end
    end
    invitations = invitations.where("created_at >= ?", params[:created_at_from]) if params[:created_at_from]
    invitations = invitations.where("created_at <= ?", params[:created_at_to]) if params[:created_at_to]
    return invitations
  end

  # Finds all invitations matching the parameters. Also, if the job associated with an invitation
  #   doesn't meet the filters, the offer wouldn't be included in the results.
  # @param params [Hash] the parameters to search the invitations with.
  # @option params [String] :provider_id The id of the provider.
  # @option params [Integer] :job_id The id of the job the invitation is for.
  # @option params [String] :status The status of the invitation, can be a single String or an Array of Strings.
  # @option params [String] :created_at_from The lower limit for the creation date of the invitation.
  # @option params [String] :created_at_to The upper limit for the creation date of the invitation.
  # @option params [String] :job_filter The filters each offer job should meet.
  # @return [Array<Invitation>] all matching invitations.
  def find_by_with_job_filter(params)
    return find_by(params) if params[:job_filter].nil?
    query = TDJobs::HashQuery.job_query(params[:job_filter])
    invitations = find_by(params)
    matched_ids = []
    invitations.each do |invitation|
      job = Job.where(id: invitation.job_id)
      unless TDJobs::HashQuery.process_hash(job, query).empty?
        matched_ids.push(offer.id)
      end
    end
    Invitation.where(id: matched_ids)
  end

  # Searches for invitations according to the given :params, the :find_by_with_job_filter is called
  #   and according to the response, some additional attributes related to pagination will be
  #   returned.
  # @param params (#see :find_by_with_job_filter)
  # @param page [Integer] Number of page to be retrieved
  # @param per_page [Integer] How many elements will be there for page.
  # @return [Hash] A hash containing all matched invitations and attributes related to pagination.
  def paginated_find(params, page = nil, per_page = nil)
    matched = find_by_with_job_filter(params)
    response = {}
    response[:total_items] = matched.count
    response[:current_page] = 1
    response[:total_pages] = 1
    if (page.is_a?(Integer) && per_page.is_a?(Integer))
      response[:total_pages] = (matched.count.to_f / per_page.to_f).ceil
      response[:current_page] = page
      matched = matched.paginate(page: page, per_page: per_page)
    end
    response[:invitations] = matched
    response
  end

  emit! :invitation_created
  # Creates a new invitation with the given attributes.
  # @param attributes [Hash] the properties to create an invitation with.
  # @option attributes [String] :provider_id The id of the provider. (required)
  # @option attributes [Integer] :job_id The id of the job the invitation is created for. (required)
  # @option attributes [String] :description The description for the invitation.
  # @return [Invitation] the created invitation.
  # @raise [ActiveRecord::RecordNotFound] if the specified job doesn't exist.
  # @raise [TDJobs::InvalidStatus] if the given job is not active.
  def create_new(attributes)
    invitation = {}
    invitation[:status] = :CREATED
    invitation[:provider_id] = attributes[:provider_id]
    invitation[:job_id] = attributes[:job_id]
    invitation[:description] = attributes[:description]
    validate_job attributes[:job_id]
    created_invitation = Invitation.create! invitation
    InvitationEvent.create(description: 'Invitation created', status: created_invitation.status,
                           invitation: created_invitation)
    created_invitation
  end

  emit! :invitation_sent
  # Sends the given invitation.
  # @param id [Integer] the id of the invitation to be sent.
  # @return [Invitation] the sent invitation.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any invitation.
  # @raise [TDJobs::InvalidStatus] if the given invitation can't be sent.
  def send(id)
    invitation = Invitation.find(id)
    if (invitation.status.to_sym == :CREATED)
      sent_invitation = update_invitation(id, status: :SENT)
      InvitationEvent.create(description: 'Invitation sent',
                             status: sent_invitation.status, invitation: sent_invitation)
      sent_invitation
    else
      raise TDJobs::InvalidStatus,
            "Can't send Invitation. Invitation is: " + invitation.status
    end
  end

  emit! :invitation_withdrawn
  # Withdraws the given invitation.
  # @param id [Integer] the id of the invitation to be withdrawn.
  # @return [Invitation] the withdrawn invitation.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any invitation.
  # @raise [TDJobs::InvalidStatus] if the given invitation can't be withdrawn.
  def withdraw(id)
    invitation = Invitation.find(id)
    if ([:CREATED, :SENT].include?(invitation.status.to_sym))
      withdrawn_invitation = update_invitation(id, status: :WITHDRAWN)
      InvitationEvent.create(description: 'Invitation withdrawn',
                             status: withdrawn_invitation.status, invitation: withdrawn_invitation)
      withdrawn_invitation
    else
      raise TDJobs::InvalidStatus,
            "Can't withdraw Invitation. Invitation is: " + invitation.status
    end
  end

  emit! :invitation_accepted
  # Accepts the given invitation.
  # @param id [Integer] the id of the invitation to be accepted.
  # @return [Invitation] the accepted invitation.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any invitation.
  # @raise [TDJobs::InvalidStatus] if the given invitation can't be accepted.
  def accept(id)
    invitation = Invitation.find(id)
    if (invitation.status.to_sym == :SENT)
      accepted_invitation = update_invitation(id, status: :ACCEPTED)
      InvitationEvent.create(description: 'Invitation accepted', status: accepted_invitation.status,
                             invitation: accepted_invitation)
      accepted_invitation
    else
      raise TDJobs::InvalidStatus,
            "Can't accept Invitation. Invitation is: " + invitation.status
    end
  end

  emit! :invitation_rejected
  # Rejects the given invitation.
  # @param id [Integer] the id of the invitation to be rejected.
  # @return [Invitation] the rejected invitation.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any invitation.
  # @raise [TDJobs::InvalidStatus] if the given invitation can't be rejected.
  def reject(id)
    invitation = Invitation.find(id)
    if (invitation.status.to_sym == :SENT)
      rejected_invitation = update_invitation(id, status: :REJECTED)
      InvitationEvent.create(description: 'Invitation rejected', status: rejected_invitation.status,
                             invitation: rejected_invitation)
      rejected_invitation
    else
      raise TDJobs::InvalidStatus,
            "Can't reject Invitation. Invitation is: " + invitation.status
    end
  end

  private

  # Updates an invitation with the given attributes.
  # @param id [Integer] the id of the invitation to be updated.
  # @param attributes [Hash] the properties to modify the invitation with.
  # @option attributes [String] :provider_id The new id of the provider.
  # @option attributes [Integer] :job_id The new id of the job the invitation is created for.
  # @option attributes [String] :status The new status for the invitation.
  # @return [Invitation] the updated invitation.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any invitation.
  # @raise [ActiveRecord::RecordInvalid] if the new properties for the invitation are not valid.
  def update_invitation(id, attributes)
    updated_invitation = Invitation.update(id, attributes)
    if updated_invitation.valid?
      updated_invitation
    else
      raise ActiveRecord::RecordInvalid, updated_invitation
    end
  end

  # Validates whether the given job is active or not.
  # @param id [Integer] the id of the job to check its status.
  # @return [Job] the active job.
  # @raise [ActiveRecord::RecordNotFound] if the given id doesn't correspond to any job.
  # @raise [TDJobs::InvalidStatus] if the job with the given id is not active.
  def validate_job(job_id)
    job = Job.find job_id
    unless job.active?
      raise TDJobs::InvalidStatus, "Job with id='#{job.id}' is not active, it is #{job.status}"
    end
  end
end
