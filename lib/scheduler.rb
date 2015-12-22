# require Rails.root.join('lib', 'td_jobs', 'configuration.rb')

if (ENV['RAILS_ENV'] != 'test')
  # Schedule all your jobs here.
  scheduler = Rufus::Scheduler.new
  puts 'SCHEDULER: Scheduler initialized.'
  #
  # scheduler.in '20m' do
  #   puts "order ristretto"
  # end
  #
  # scheduler.at 'Wed Jul 22 09:30:43 +0500 20015' do
  #   puts 'order pizza'
  # end
  #
  # scheduler.every '5h' do
  #   # every 5h
  #   puts 'activate security system'
  # end
  #

  # If activated, every day at 23:59 look for all non-closed jobs which are due today or before.
  if(TDJobs.configuration.auto_close_jobs?)
    puts 'SCHEDULER: Scheduled automatic job closing.'
    scheduler.cron '59 23 * * *' do
      JobUtils.close_all_due
    end
  end
end
