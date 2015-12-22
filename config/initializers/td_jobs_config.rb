require Rails.root.join('lib', 'td_jobs', 'configuration.rb')

TDJobs.configure do |config|
  config.autoinvite = false
  config.auto_close_jobs = false
  config.application_secret = "ah15Af6130kgoa5sD1yUQioaP"
end
