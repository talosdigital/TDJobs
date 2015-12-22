namespace :rubocop do
  # Usage:    $ rake rubocop:check[optional params]
  # Examples: $ rake rubocop:check
  #           $ rake rubocop:check[--format,simple]
  #           $ rake rubocop:check[--format,offenses,app/api]
  task :check, [:params] do |_task, args|
    cmd = "rubocop --config .rubocop_config.yml #{args[:params]} #{args.extras.join(' ')}"
    system "#{cmd}"
  end
end
