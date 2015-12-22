module TDJobs
  module StrongParamsHelper
    extend Grape::API::Helpers

    def allowed_params
      declared(params, include_missing: false)
    end
  end
end
