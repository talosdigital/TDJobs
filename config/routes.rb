Rails.application.routes.draw do
  mount TDJobs::Root => '/api'
  mount GrapeSwaggerRails::Engine => '/doc'
end
