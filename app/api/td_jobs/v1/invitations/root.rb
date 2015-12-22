module TDJobs
  module V1
    module Invitations
      # Contains endpoint methods for Invitations, hits service methods. See grape-swagger
      #   documentation.
      class Root < Grape::API
        helpers StrongParamsHelper

        desc 'searches for invitations', entity: Entities::Invitation, is_array: true
        params do
          optional :provider_id, type: String, desc: "The id of the invitation's provider"
          optional :job_id, type: Integer, desc: "The id of the invitation's job"
          optional :status, type: Array[String], desc: "The invitation's status"
          optional :created_at_from, type: Date, desc: "The start of the range for the invitation's date"
          optional :created_at_to, type: Date, desc: "The end of the range for the invitation's date"
        end
        get do
          present InvitationService.instance.find_by(allowed_params), with: Entities::Invitation
        end

        desc 'searches for invitations and responds using pagination', entity: Entities::Offer
        params do
          optional :provider_id, type: String, desc: "The id of the invitation's provider"
          optional :job_id, type: Integer, desc: "The id of the invitation's job"
          optional :status, type: Array[String], desc: "The invitation's status"
          optional :created_at_from, type: Date,
                                     desc: "The start of the range for the invitation's date"
          optional :created_at_to, type: Date,
                                   desc: "The end of the range for the invitation's date"
          optional :job_filter, desc: "The filters each invitation job should meet. "
          optional :page, type: Integer, desc: 'Page of results to be shown.'
          optional :per_page, type: Integer, desc: 'Items per page to be shown in the results.'
        end
        get 'pagination' do
          begin
            page = params[:page]
            per_page = params[:per_page]
            present InvitationService.instance.paginated_find(allowed_params, page, per_page),
                    with: Entities::InvitationPaginated
          rescue JSON::JSONError => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::InvalidQuery => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'gets an invitation by id', entity: Entities::Invitation
        params do
          requires :id, type: Integer, desc: 'The id of the Invitation'
        end
        get ':id' do
          begin
            present InvitationService.instance.find(params[:id]), with: Entities::Invitation
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          end
        end

        desc 'creates a new invitation', entity: Entities::Invitation
        params do
          requires :provider_id, type: String, desc: "The id of the invitation's provider"
          requires :job_id, type: Integer, desc: "The id of the invitation's job"
          optional :description, type: String, desc: "The invitation's description"
        end
        post do
          begin
            present InvitationService.instance.create_new(allowed_params),
                    with: Entities::Invitation
          # -- Not needed so far.
          # rescue ActiveRecord::RecordInvalid => exception
          #   error!(exception.message, :bad_request)
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'sends an invitation', entity: Entities::Invitation
        params do
          requires :id, type: Integer, desc: 'The id of the invitation to be sent'
        end
        put ':id/send' do
          begin
            present InvitationService.instance.send(params[:id]), with: Entities::Invitation
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'withdraws an invitation', entity: Entities::Invitation
        params do
          requires :id, type: Integer, desc: 'The id of the invitation to be withdrawn'
        end
        put '/:id/withdraw' do
          begin
            present InvitationService.instance.withdraw(params[:id]), with: Entities::Invitation
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'accepts an invitation', entity: Entities::Invitation
        params do
          requires :id, type: Integer, desc: 'The id of the invitation to be accepted'
        end
        put '/:id/accept' do
          begin
            present InvitationService.instance.accept(params[:id]), with: Entities::Invitation
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'rejects an invitation', entity: Entities::Invitation
        params do
          requires :id, type: Integer, desc: 'The id of the invitation to be rejected'
        end
        put '/:id/reject' do
          begin
            present InvitationService.instance.reject(params[:id]), with: Entities::Invitation
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
