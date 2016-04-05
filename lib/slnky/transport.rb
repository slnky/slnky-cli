require 'amqp'
# require 'slnky/transport/queues'
# require 'slnky/transport/exchanges'

module Slnky
  module Transport
    class << self
      def setup(config)
        @instance ||= begin
          Slnky::Transport::Rabbit.new(config)
        end
      end

      def instance
        @instance
      end
    end

    class Rabbit
      attr_reader :channel
      attr_reader :exchanges
      attr_reader :queues
      attr_reader :stopper

      def initialize(config)
        @host = config.rabbit.host
        @port = config.rabbit.port
        @url = "amqp://#{@host}:#{@port}"
        @config = config
        @channel = nil
        @exchanges = {}
        @queues = {}
      end

      def start!(service, &block)
        AMQP.start(@url) do |connection|
          @connection = connection
          @channel = AMQP::Channel.new(@connection)
          @channel.on_error do |ch, channel_close|
            raise "Channel-level exception: #{channel_close.reply_text}"
          end

          Signal.trap("INT", proc { self.stop!('Interrupted') })
          Signal.trap("TERM", proc { self.stop!('Terminated') })

          exchange('events', :fanout)
          exchange('logs', :fanout)
          exchange('response', :direct)
          queue(service, 'events')

          yield self if block_given?

          queues.each do |name, queue|
            queue.subscribe do |raw|
              event = Slnky::Message.parse(raw)
              service.subscriber.for(event.name) do |name, method|
                service.send(method.to_sym, event.name, event.payload)
              end
            end
          end

          service.timers.each do |seconds, method|
            EventMachine.add_periodic_timer(seconds) do
              service.send(method.to_sym)
            end
          end
        end
      end

      def stop!(msg=nil)
        return unless @connection
        puts "#{Time.now}: stopping#{msg && " (#{msg})"}"
        @connection.close { EventMachine.stop { exit } }
      end

      def exchange(desc, type)
        raise 'attempting to create exchange without channel' unless @channel
        name = "slnky.#{desc}"
        @exchanges[desc] ||=
            case type
              when :fanout
                @channel.fanout(name)
              when :direct
                @channel.direct(name)
              else
                raise "unknown exchange type: #{ex.type}"
            end
      end

      def queue(desc, exchange, options={})
        raise 'attempting to create queue without channel' unless @channel
        name = "service.#{desc}.#{exchange}"
        options = {
            durable: true
        }.merge(options)
        @queues[desc] ||= @channel.queue(name, options).bind(@exchanges[exchange])
      end
    end
  end
end