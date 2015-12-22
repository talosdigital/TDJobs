module TDJobs
  module V1
    class Root < Grape::API

      before do
        unless valid_token?
          error!("Unauthorized application (Missing or invalid secret)", :unauthorized)
        end
      end

      helpers do
        def valid_token?
          headers['Application-Secret'] &&
            headers['Application-Secret'] == TDJobs::configuration.application_secret
        end
      end

      mount Jobs::Root => '/jobs'
      mount Invitations::Root => '/invitations'
      mount Offers::Root => '/offers'
      add_swagger_documentation(base_path: '/api/v1', hide_documentation_path: true,
                                hide_format: true)
    end
  end
end
