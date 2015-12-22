require 'bunny'

module RabbitMQ
  class RabbitMQProducer
    @@connection = nil

    #Sets the RabbitMQ server's hostname
    # @param hostname [String] The RabbitMQ server hostname.
    def self.hostname=(hostname)
      @@hostname = hostname
    end

    #Sets the RabbitMQ server's port
    # @param port [String] The RabbitMQ server port.
    def self.port=(port)
      @@port = port
    end

    #Sets the RabbitMQ server's username
    # @param username [String] The RabbitMQ server username.
    def self.username=(username)
      @@username = username
    end

    #Sets the RabbitMQ server's password
    # @param password [String] The RabbitMQ server password.
    def self.password=(password)
      @@password = password
    end

    #Sets the RabbitMQ connection retry interval
    # @param interval [Integer] The interval in seconds for every retry connection to RabbitMQ server.
    def self.connection_retry_interval=(interval)
      @@connection_retry_interval = interval
    end

    #Sets the RabbitMQ connection retry attempts
    # @param attempts [Integer] The number of attempts for retry connection to RabbitMQ server.
    def self.connection_retry_attempts=(attempts)
      @@connection_retry_attempts = attempts
    end

    #Establishes a connection with RabbitMQ server
    def self.connect
      open_connection

      return unless @@connection && @@connection.open?
    end

    #Gets the RabbitMQ connection channel
    # @return [Channel] the connection channel.
    def self.get_channel
      @@channel
    end

    #Gets the RabbitMQ channel default exchange
    # @return [Exchange] the connection channel default exchange.
    def self.get_default_exchange
      @@channel.default_exchange
    end

    #Creates a new queue for connection channel
    # @return [Queue] the queue.
    def self.get_queue(queue_name)
      get_channel.queue(queue_name)
    end

    #Creates a new fanout for connection channel
    def self.get_fanout(fanout_name)
      get_channel.fanout(fanout_name)
    end

    #Sends a message to specified queue
    def self.send_to_queue(queue_name, message)
      queue = get_queue(queue_name)
      get_default_exchange.publish(message, routing_key: queue.name)
    end

    #Sends a message to specified fanout
    def self.send_to_fanout(fanout_name, message)
      fanout = get_fanout(fanout_name)
      fanout.publish(message)
    end

    #Open a connection to RabbitMQ server with parameters set. Retries the connection based on attempts and retry interval
    private
    def self.open_connection
      if @@connection && @@connection.open?
        @@connection.close
        sleep(0.2)
      end

      retry_attempts = 1

      begin
        @@connection = Bunny.new(host: @@hostname, port: @@port, user: @@username, password: @@password, automatically_recover: false)
        @@connection.start

        @@channel = @@connection.create_channel

      rescue Exception => e
        puts "Cannot connect to RabbitMQ. #{e.message}. Recovering manually (#{retry_attempts}/#{@@connection_retry_attempts}) ..."
        retry_attempts += 1
        sleep @@connection_retry_interval
        retry if retry_attempts <= @@connection_retry_attempts
      end
    end
  end
end
