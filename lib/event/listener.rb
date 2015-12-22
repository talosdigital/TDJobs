module Event
  class Listener
    def self.configure(&block)
      class_exec(&block)
    end

    def self.before(event, &action)
      Event::Manager.add_observer(:before, event) do |*payload|
        action.call(*payload)
      end
    end

    def self.after(event, &action)
      Event::Manager.add_observer(:after, event) do |*payload|
        action.call(*payload)
      end
    end
  end
end
