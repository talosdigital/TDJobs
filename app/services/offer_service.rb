# Handles all logic regarding Offers.
class OfferService
  extend Event::Emitter
  include Singleton

  # Finds an Offer.
  # @param [Integer] id the Offer's id.
  # @return [Offer] the found Offer.
  # @raise [ActiveRecord::RecordNotFound] when the id is not valid.
  def find(id)
    Offer.find(id)
  end

  # Finds all offers matching the parameters.
  # @param params [Hash] the parameters to search the offer with.
  # @option params [String] :provider_id The id of the provider.
  # @option params [Integer] :job_id The id of the job the offer is for.
  # @option params [String] :status The status of the offer, can be a single String or an Array of Strings.
  # @option params [String] :created_at_from The lower limit for the creation date of the offer.
  # @option params [String] :created_at_to The upper limit for the creation date of the offer.
  # @return [Array<Invitation>] all matching offers.
  def find_by(params)
    offers = Offer.order(:id)
    offers = offers.where("provider_id = ?", params[:provider_id]) if params[:provider_id]
    offers = offers.where("job_id = ?", params[:job_id]) if params[:job_id]
    if params[:status]
      if params[:status].kind_of? Array
        offers = offers.where("status in (?)", params[:status])
      else
        offers = offers.where("status = ?", params[:status])
      end
    end
    offers = offers.where("created_at >= ?", params[:created_at_from]) if params[:created_at_from]
    offers = offers.where("created_at <= ?", params[:created_at_to]) if params[:created_at_to]
    return offers
  end

  # Finds all offers matching the given parameters. Also, if the job associated with an offer
  #   doesn't meet the filters, the offer wouldn't be included in the results.
  # @param params [Hash] the parameters to search the offer with.
  # @option params [String] :provider_id The id of the provider.
  # @option params [Integer] :job_id The id of the job the offer is for.
  # @option params [String] :status The status of the offer, can be a single String or an Array of Strings.
  # @option params [String] :created_at_from The lower limit for the creation date of the offer.
  # @option params [String] :created_at_to The upper limit for the creation date of the offer.
  # @option params [String] :job_filter The filters each offer job should meet.
  # @return [Array<Invitation>] all matching offers.
  # @raise [TDJobs::InvalidQuery] if invalid attributes were given or no attributes were given.
  def find_by_with_job_filter(params)
    return find_by(params) if params[:job_filter].nil?
    query = TDJobs::HashQuery.job_query(params[:job_filter])
    offers = find_by(params)
    matched_ids = []
    offers.each do |offer|
      job = Job.where(id: offer.job_id)
      unless TDJobs::HashQuery.process_hash(job, query).empty?
        matched_ids.push(offer.id)
      end
    end
    Offer.where(id: matched_ids)
  end

  # Searches for offers according to the given :params, the :find_by_with_job_filter is called
  #   and according to the response, some additional attributes related to pagination will be
  #   returned.
  # @param params (#see :find_by_with_job_filter)
  # @param page [Integer] Number of page to be retrieved
  # @param per_page [Integer] How many elements will be there for page.
  # @return [Hash] A hash containing all matched offers and attributes related to pagination.
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
    response[:offers] = matched
    response
  end

  emit! :offer_created
  # Creates an Offer.
  # @param [Hash] offer_attrs the Offer's attributes.
  # @option offer_attrs [Fixnum] :job_id the id of the Job the Offer references.
  # @option offer_attrs [Fixnum] :invitation_id the id of the Invitation the Offer references.
  # @option offer_attrs [String] :provider_id the id of the external provider the Offer belongs to.
  # @option offer_attrs [String] :description the Offer's description.
  # @option offer_attrs [JSON] :metadata the Offer's metadata.
  # @return [Offer] the created Offer.
  def create(offer_attrs)
    offer_attrs[:status] = :CREATED
    job = validate_job(offer_attrs[:job_id], offer_attrs[:invitation_id])
    offer_attrs[:invitation] = validate_invitation(offer_attrs[:invitation_id],
                                                   offer_attrs[:provider_id],
                                                   offer_attrs[:job_id])
    offer_attrs[:metadata] = job.metadata unless offer_attrs[:metadata]
    offer = Offer.create!(offer_attrs.except(:invitation_id))
    OfferEvent.create(offer: offer, description: 'Offer created', provider_id: offer[:provider_id],
                      status: :CREATED)
    generate_offer_record(offer, :CREATED, offer_attrs[:description])
    return offer
  end

  emit! :offer_sent
  # Validates the Offer's current status and sets the status as SENT, if possible.
  # Creates an OfferEvent.
  # @param [Fixnum] id the Offer to be sent.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  def send(id)
    offer = Offer.find(id)
    if (offer.status.to_sym == :CREATED)
      offer = Offer.update(id, status: :SENT)
      # Creating SENT event
      OfferEvent.create(offer: offer, description: 'Offer sent', provider_id: offer[:provider_id],
                        status: :SENT)
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't send a non-created offer"
    end
  end

  emit! :offer_resent
  # Validates the Offer's current status and sets the status as RESENT, if possible.
  # Creates an OfferEvent, and an OfferRecord.
  # @param [Fixnum] id the Offer to be resent.
  # @param [Hash] attrs the resend attributes.
  # @option attrs [String] :reason the reason why the Offer was resent.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  # @see OfferRecord
  def resend(id, attrs = {})
    offer = Offer.find(id)
    if (offer.status.to_sym == :RETURNED)
      update_attrs = { status: :RESENT }
      if attrs[:metadata]
        update_attrs[:metadata] = attrs[:metadata]
      end
      offer = Offer.update(id, update_attrs)
      # Creating RESENT event and record
      OfferEvent.create(offer: offer,
                        description: 'Offer resent',
                        provider_id: offer[:provider_id],
                        status: :RESENT)
      generate_offer_record(offer, :RESENT, attrs[:reason])
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't resend a non-returned offer"
    end
  end

  emit! :offer_withdrawn
  # Validates the Offer's current status and sets the status as WITHDRAWN, if possible.
  # Creates an OfferEvent.
  # @param [Fixnum] id the Offer to be withdrawn.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  # @see OfferRecord
  def withdraw(id)
    offer = Offer.find(id)
    if ([:SENT, :RETURNED].include?(offer.status.to_sym))
      offer = Offer.update(id, status: :WITHDRAWN)
      # Creating WITHDRAWN event
      OfferEvent.create(offer: offer, description: 'Offer withdrawn',
                        provider_id: offer[:provider_id], status: :WITHDRAWN)
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't withdraw a non-sent or non-returned offer"
    end
  end

  emit! :offer_returned
  # Validates the Offer's current status and sets the status as RETURNED, if possible.
  # Creates an OfferEvent, and an OfferRecord.
  # @param [Fixnum] id the Offer to be returned.
  # @param [Hash] attrs the return attributes.
  # @option attrs [String] :reason the reason why the Offer was returned.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  # @see OfferRecord
  def return_offer(id, attrs = {})
    offer = Offer.find(id)
    if ([:SENT, :RESENT].include?(offer.status.to_sym))
      offer = Offer.update(id, status: :RETURNED)
      # Creating RETURNED event
      OfferEvent.create(offer: offer,
                        description: 'Offer returned',
                        provider_id: offer[:provider_id],
                        status: :RETURNED)
      generate_offer_record(offer, :RETURNED, attrs[:reason])
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't return a non-sent or non-resent offer"
    end
  end

  emit! :offer_rejected
  # Validates the Offer's current status and sets the status as REJECTED, if possible.
  # Creates an OfferEvent.
  # @param [Fixnum] id the Offer to be rejected.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  def reject(id)
    offer = Offer.find(id)
    if ([:RESENT, :SENT].include?(offer.status.to_sym))
      offer = Offer.update(id, status: :REJECTED)
      # Creating REJECTED event
      OfferEvent.create(offer: offer, description: 'Offer rejected',
                        provider_id: offer[:provider_id], status: :REJECTED)
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't reject a non-sent or non-resent offer"
    end
  end

  emit! :offer_accepted
  # Validates the Offer's current status and sets the status as ACCEPTED, if possible.
  # Creates an OfferEvent.
  # @param [Fixnum] id the Offer to be accepted.
  # @return [Offer] the updated Offer.
  # @raise [TDJobs::InvalidStatus] when the Offer's status is not valid.
  # @see OfferEvent
  def accept(id)
    offer = Offer.find(id)
    if offer && [:SENT, :RESENT].include?(offer.status.to_sym)
      offer = Offer.update(id, status: :ACCEPTED)
      # Creating ACCEPTED event
      OfferEvent.create(offer: offer, description: 'Offer accepted',
                        provider_id: offer[:provider_id], status: :ACCEPTED)
      return offer
    else
      raise TDJobs::InvalidStatus, "Can't accept a non-sent or non-resent offer"
    end
  end

  private
  # Validates that the job is active, or if it's invitation-only.
  def validate_job(job_id, invitation_id)
    job = Job.find job_id
    if(!job.active?)
      raise TDJobs::InvalidStatus, "Job with id='#{job.id}' is not active, it is #{job.status}"
    elsif job.invitation_only && invitation_id.nil?
      raise TDJobs::MissingInvitation, "Can't create an Offer for this Job without an Invitation"
    end
    return job
  end

  # Validates an Invitation's status, and that it belongs to its Offer's provider.
  def validate_invitation(invitation_id, provider_id, job_id)
    return unless invitation_id
    invitation = Invitation.find(invitation_id)
    unless invitation.provider_id == provider_id
      raise TDJobs::ProviderMismatch, "Can't create an Offer based on a Invitation for a different provider"
    end
    unless invitation.job_id == job_id
      raise TDJobs::JobMismatch, "Can't create an Offer based on a Invitation for a different job"
    end
    unless (invitation.status.to_sym == :ACCEPTED)
      raise TDJobs::InvalidStatus, "Can't make an offer based on an invitation that is "\
                                     "not accepted, current invitation is: #{invitation.status}"
    end
    return invitation
  end

  # Receives some parameters and creates an Offer Record with them.
  # @param offer [Offer] the offer whose record will be persisted.
  # @param record_type [Symbol] the type of record ((:CREATED, :RETURNED, :RESENT))
  # @param reason [String] the reason for the offer to be created, returned or resent.
  # @return OfferRecord
  # @raise [ArgumentError] when no offer or record_type are specified.
  # @raise [TDJobs::InvalidRecordType] when record_type is not a valid type.
  def generate_offer_record(offer, record_type, reason)
    record_attrs = {
      offer: offer,
      record_type: record_type,
    }
    record_attrs[:reason] = reason if reason
    OfferRecordService.instance.create_record(record_attrs)
  end
end
