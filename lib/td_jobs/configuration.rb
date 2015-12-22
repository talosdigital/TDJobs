module TDJobs
  # For a block { |config| ... }
  # @yield [config] passes the Configuration object.
  # @yieldparam config the Configuration object to be configured.
  # @see Configuration
  # @example Configure TD Jobs
  #   TDJobs.configure do |config|
  #     config.autoinvite = false
  #     config.auto_close_jobs = false
  #   end
  def self.configure
    yield Configuration.instance if block_given?
  end

  # @return the current Configuration.
  def self.configuration
    Configuration.instance
  end

  # Contains all configuration options and accessors.
  class Configuration
    include Singleton

    # The configuration options array. It's used to generate all the writers.
    CONFIG_OPTIONS = [:autoinvite, :auto_close_jobs, :auto_send_invitation, :application_secret]

    # @!attribute autoinvite
    # @return [Boolean] sets the autoinvite flag.

    # @!attribute auto_close_jobs
    # @return [Boolean] sets the auto_close_jobs flag.

    # @!attribute auto_send_invitation
    # @return [Boolean] sets the auto_send_invitation flag.

    # @!attribute application_secret
    # @return [String] sets the application secret.

    attr_writer(*CONFIG_OPTIONS)

    # Defaults to false
    # @return [Boolean] whether autoinvite is active or not.
    def autoinvite?
      @autoinvite = false if @autoinvite.nil?
      @autoinvite
    end

    # Defaults to false
    # @return [Boolean] whether auto_send_invitation is active or not.
    def auto_close_jobs?
      @auto_close_jobs = false if @auto_close_jobs.nil?
      @auto_close_jobs
    end

    # Defaults to false
    # @return [Boolean] whether auto_send_invitation is active or not.
    def auto_send_invitation?
      @auto_send_invitation = false if @auto_send_invitation.nil?
      @auto_send_invitation
    end

    # Defaults to nil
    # @return [String] the application secret which allows other applications to make requests.
    def application_secret
      @application_secret
    end
  end
end
