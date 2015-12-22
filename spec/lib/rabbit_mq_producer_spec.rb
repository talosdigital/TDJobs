require 'rails_helper'
require 'faker'
require 'bunny_mock'
require 'spec_helper'

RSpec.describe RabbitMQ::RabbitMQProducer do
  describe '.send_to_queue' do
    context 'when something sends a message to queue' do
      it 'should send a message to queue' do
        bunny = BunnyMock.new

        queue = bunny.queue(
          'my_queue',
          durable: true,
          auto_delete: true,
          exclusive: false,
          arguments: { 'x-ha-policy' => 'all' }
        )
        exchange = bunny.exchange(
          'my_exchange',
          type: :direct,
          durable: true,
          auto_delete: true
        )
        queue.bind(exchange)

        allow(RabbitMQ::RabbitMQProducer).to receive(:get_queue).and_return(queue)
        allow(RabbitMQ::RabbitMQProducer).to receive(:get_default_exchange).and_return(exchange)

        # Basic assertions
        expect(queue.messages).to be_empty
        expect(exchange).to be_bound_to 'my_queue'
        expect(queue.default_consumer.message_count).to eq 0

        msg_1 = Faker::Lorem.sentence
        msg_2 = Faker::Lorem.sentence
        msg_3 = Faker::Lorem.sentence

        # Send some messages ...
        RabbitMQ::RabbitMQProducer.send_to_queue('my_queue', msg_1)
        RabbitMQ::RabbitMQProducer.send_to_queue('my_queue', msg_2)
        RabbitMQ::RabbitMQProducer.send_to_queue('my_queue', msg_3)

        # Verify state of the queue
        expect(queue.messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]

        expect(queue.snapshot_messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]
      end
    end #context
  end #describe

  describe '.send_to_fanout' do
    context 'when something sends a message to fanout' do
      it 'should send a message to fanout with two queues' do
        bunny = BunnyMock.new

        queue_1 = bunny.queue(
          'my_queue_1',
          durable: true,
          auto_delete: true,
          exclusive: false,
          arguments: { 'x-ha-policy' => 'all' }
        )

        queue_2 = bunny.queue(
          'my_queue_2',
          durable: true,
          auto_delete: true,
          exclusive: false,
          arguments: { 'x-ha-policy' => 'all' }
        )

        fanout = bunny.exchange(
          'my_fanout',
          type: :direct,
          durable: true,
          auto_delete: true
        )

        #Binding both queues
        queue_1.bind(fanout)
        queue_2.bind(fanout)
        
        allow(RabbitMQ::RabbitMQProducer).to receive(:get_fanout).and_return(fanout)

        # Basic assertions
        expect(queue_1.messages).to be_empty
        expect(queue_2.messages).to be_empty
        
        expect(fanout).to be_bound_to 'my_queue_1'
        expect(fanout).to be_bound_to 'my_queue_2'
        
        expect(queue_1.default_consumer.message_count).to eq 0
        expect(queue_2.default_consumer.message_count).to eq 0
        
        expect(fanout.queues.count).to eq(2)

        msg_1 = Faker::Lorem.sentence
        msg_2 = Faker::Lorem.sentence
        msg_3 = Faker::Lorem.sentence

        # Send some messages ...
        RabbitMQ::RabbitMQProducer.send_to_fanout('my_fanout', msg_1)
        RabbitMQ::RabbitMQProducer.send_to_fanout('my_fanout', msg_2)
        RabbitMQ::RabbitMQProducer.send_to_fanout('my_fanout', msg_3)

        # Verify state of the queue_1
        expect(queue_1.messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]

        expect(queue_1.snapshot_messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]

        # Verify state of the queue_2
        expect(queue_2.messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]

        expect(queue_2.snapshot_messages).to eq [
          msg_1,
          msg_2,
          msg_3
        ]

      end #it
    end #context
  end #describe

end
