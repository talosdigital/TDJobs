module TDJobs
  module V1
    module Offers
      # Contains endpoint methods for Offers, hits service methods. See grape-swagger documentation.
      class Root < Grape::API
        helpers StrongParamsHelper

        desc 'searches for offers', entity: Entities::Offer, is_array: true
        params do
          optional :provider_id, type: String, desc: "The id of the offer's provider"
          optional :job_id, type: Integer, desc: "The id of the offer's job"
          optional :status, type: Array[String], desc: "The offer's status"
          optional :created_at_from, type: Date, desc: "The start of the range for the offer's date"
          optional :created_at_to, type: Date, desc: "The end of the range for the offer's date"
          optional :job_filter, desc: "The filters each offer job should meet. "
        end
        get do
          begin
            if params[:job_filter].nil?
              present OfferService.instance.find_by(allowed_params), with: Entities::Offer
            else
              present OfferService.instance.find_by_with_job_filter(allowed_params),
                      with: Entities::Offer
            end
          rescue JSON::JSONError => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::InvalidQuery => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'searches for an offers and responds using pagination', entity: Entities::Offer
        params do
          optional :provider_id, type: String, desc: "The id of the offer's provider"
          optional :job_id, type: Integer, desc: "The id of the offer's job"
          optional :status, type: Array[String], desc: "The offer's status"
          optional :created_at_from, type: Date, desc: "The start of the range for the offer's date"
          optional :created_at_to, type: Date, desc: "The end of the range for the offer's date"
          optional :job_filter, desc: "The filters each offer job should meet. "
          optional :page, type: Integer, desc: 'Page of results to be shown.'
          optional :per_page, type: Integer, desc: 'Items per page to be shown in the results.'
        end
        get 'pagination' do
          begin
            page = params[:page]
            per_page = params[:per_page]
            present OfferService.instance.paginated_find(allowed_params, page, per_page),
                    with: Entities::OfferPaginated
          rescue JSON::JSONError => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::InvalidQuery => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'gets an offer by id', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the Offer'
        end
        get ':id' do
          service = OfferService.instance
          begin
            present service.find(params[:id]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          end
        end

        desc 'creates a new offer', entity: Entities::Offer
        params do
          requires :job_id, type: Integer, desc: "The id of the offer's job"
          optional :invitation_id, type: Integer, desc: 'The invitation id, if there is one'
          optional :description, type: String, desc: "The offer's description"
          requires :provider_id, type: String, desc: "The id of the offer's provider"
          optional :metadata, type: Hash, desc: "The offer's metadata"
        end
        post do
          begin
            present OfferService.instance.create(allowed_params), with: Entities::Offer
          rescue ActiveRecord::RecordInvalid => exception
            error!(exception.message, :bad_request)
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::MissingInvitation => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::ProviderMismatch => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::JobMismatch => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'sends an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be sent'
        end
        put ':id/send' do
          begin
            present OfferService.instance.send(params[:id]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'resends an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be resent'
          optional :reason, type: String, desc: 'The reason to have resent the offer'
          optional :metadata, type: Hash, desc: "The offer's metadata"
        end
        put ':id/resend' do
          begin
            present OfferService.instance.resend(params[:id],
                                                 reason: params[:reason],
                                                 metadata: params[:metadata]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'withdraws an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be withdrawn'
        end
        put ':id/withdraw' do
          begin
            present OfferService.instance.withdraw(params[:id]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'returns an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be returned'
          optional :reason, type: String, desc: 'The reason to have returned the offer'
        end
        put ':id/return' do
          begin
            present OfferService.instance.return_offer(params[:id],
                                                       reason: params[:reason]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'rejects an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be rejected'
        end
        put ':id/reject' do
          begin
            present OfferService.instance.reject(params[:id]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'accepts an offer', entity: Entities::Offer
        params do
          requires :id, type: Integer, desc: 'The id of the offer to be accepted'
        end
        put ':id/accept' do
          begin
            present OfferService.instance.accept(params[:id]), with: Entities::Offer
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end
      end
    end
  end
end
