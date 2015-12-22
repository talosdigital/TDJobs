require 'rails_helper'

RSpec.describe Event::Emitter do
  describe '.method_added' do
    context 'when child class method emit event' do
      it 'should call Event::Manager.emit' do
        class Dummy1
          extend Event::Emitter
          emit! :dummy_event1
          def dumy_method
          end
        end

        expect(Event::Manager).to receive(:emit).with(:before, :dummy_event1)
        expect(Event::Manager).to receive(:emit).with(:after, :dummy_event1, nil)

        test_dummy = Dummy1.new
        test_dummy.dumy_method
      end
    end

    context "when child class method don't emit event" do
      it 'should not call Event::Manager.emit' do
        class Dummy2
          extend Event::Emitter

          def dumy_method
          end
        end

        expect(Event::Manager).not_to receive(:emit)
        expect(Event::Manager).not_to receive(:emit)

        test_dummy = Dummy2.new
        test_dummy.dumy_method
      end
    end

    context 'when :before observer return false' do
      it 'should not call Event::Manager.emit :after' do
        class Dummy3
          extend Event::Emitter
          emit! :dummy_event3
          def dumy_method
          end
        end
        Event::Manager.add_observer(:before, :dummy_event3) do |*_args|
          false
        end

        expect(Event::Manager).to receive(:emit).with(:before, :dummy_event3).and_call_original
        expect(Event::Manager).not_to receive(:emit).with(:after, :dummy_event3, nil)

        test_dummy = Dummy3.new
        test_dummy.dumy_method
      end
    end
  end
end
