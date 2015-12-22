module TDJobs
  module V1
    module Jobs
      # Contains endpoint methods for Jobs, hits service methods. See grape-swagger documentation.
      class Root < Grape::API
        helpers StrongParamsHelper

        desc 'searches for a job', entity: Entities::Job
        params do
          requires :query, desc: 'The attributes that should the job meet'
        end
        get 'search' do
          begin
            present JobService.instance.search(params[:query])
          rescue JSON::JSONError => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::InvalidQuery => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'searches for a job and responds using pagination', entity: Entities::Job
        params do
          requires :query, desc: 'The attributes that should the job meet'
          optional :page, type: Integer, desc: 'Page of results to be shown.'
          optional :per_page, type: Integer, desc: 'Items per page to be shown in the results.'
        end
        get 'search/pagination' do
          begin
            page = params[:page]
            per_page = params[:per_page]
            present JobService.instance.paginated_search(params[:query], page, per_page)
          rescue JSON::JSONError => exception
            error!(exception.message, :bad_request)
          rescue TDJobs::InvalidQuery => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'lists all jobs', entity: Entities::Job, is_array: true
        get do
          service = JobService.instance
          present service.find_all, with: Entities::Job
        end

        desc 'gets a job by id', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job'
        end
        get ':id' do
          service = JobService.instance
          begin
            present service.find(params[:id]), with: Entities::Job
            # TODO: There's no way RecordNotFound can be raised here. if Job.find doesn't yield
            # any results, it doesn't raise an exception.
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          end
        end

        desc 'creates a new job', entity: Entities::Job
        params do
          requires :name, type: String, desc: "The job's name"
          requires :description, type: String, desc: "The job's description"
          requires :owner_id, type: String, desc: "The id of the job's owner"
          requires :due_date, type: Date, desc: "The job's due date"
          requires :start_date, type: Date, desc: "The job's start date"
          requires :finish_date, type: Date, desc: "The job's finish date"
          optional :invitation_only, type: Boolean,
                                     desc: 'Whether the Job recieve offers only by invitation'
          optional :metadata, type: Hash, desc: "The job's metadata"
        end
        post do
          service = JobService.instance
          begin
            present service.create(allowed_params), with: Entities::Job
          rescue ActiveRecord::RecordInvalid => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'updates a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be updated'
          optional :description, type: String, desc: "The new job's description"
          optional :name, type: String, desc: "The new job's name"
          optional :start_date, type: Date, desc: "The new job's start date"
          optional :finish_date, type: Date, desc: "The new job's finish date"
          optional :due_date, type: Date, desc: "The new job's due date"
          optional :invitation_only, type: Boolean,
                                     desc: 'Whether the Job recieve offers only by invitation'
          optional :metadata, type: Hash, desc: "The new job's metadata"
        end
        put ':id' do
          service = JobService.instance
          begin
            present service.update(params[:id], allowed_params), with: Entities::Job
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue ActiveRecord::RecordInvalid => exception
            error!(exception.message, :bad_request)
            # TODO: :status can't be updated, so it's impossible for JobService#update to raise
            # InvalidStatus when called from here.
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'deactivates a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be deactivated'
        end
        put ':id/deactivate' do
          service = JobService.instance
          begin
            present service.deactivate(params[:id]), with: Entities::Job
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'activates a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be activated'
        end
        put ':id/activate' do
          service = JobService.instance
          begin
            present service.activate(params[:id]), with: Entities::Job
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'closes a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be closed'
        end
        put ':id/close' do
          service = JobService.instance
          begin
            present service.close(params[:id]), with: Entities::Job
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'starts a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be started'
        end
        put ':id/start' do
          begin
            present JobService.instance.start(params[:id]), with: Entities::Job
          rescue ActiveRecord::RecordNotFound => exception
            error!(exception.message, :not_found)
          rescue TDJobs::InvalidStatus => exception
            error!(exception.message, :bad_request)
          end
        end

        desc 'finishes a job', entity: Entities::Job
        params do
          requires :id, type: Integer, desc: 'The id of the job to be finished'
        end
        put ':id/finish' do
          begin
            present JobService.instance.finish(params[:id]), with: Entities::Job
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
