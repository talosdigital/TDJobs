module TDJobs
  class Root < Grape::API
    default_format :json

    mount V1::Root => '/v1'
  end
end
