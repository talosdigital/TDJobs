module Event
  class Manager
    @@observers = {
      before: {},
      after: {}
    }

    # Underscore before the argument name indicates it won't be used.
    def self.emit(tag, event, *payload, &_block)
      if @@observers[tag][event]
        response = true
        @@observers[tag][event].each do |observer|
          response = observer.call(*payload)
          break if tag == :before && response == false
        end
        response
      end
    end

    def self.add_observer(tag, event, &block)
      @@observers[tag][event] = @@observers[tag][event] || []
      @@observers[tag][event] << block
    end

    def self.show_observer
      puts @@observers
    end
  end
end
