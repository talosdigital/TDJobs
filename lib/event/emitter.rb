module Event
  module Emitter
    @__current_method = nil

    def emit!(event)
      @__event_name = event
    end

    def method_added(method_name)
      return if @__current_method && @__current_method == method_name
      @__current_method = method_name
      return unless @__event_name
      event = @__event_name
      old_method = instance_method(method_name)
      define_method method_name do |*arg|
        result_before = Event::Manager.emit :before, event, *arg
        unless result_before == false
          response = old_method.bind(self).call(*arg)
          Event::Manager.emit :after, event, response
          response
        end
      end
      @__current_method = nil
      @__event_name = nil
    end
  end
end
