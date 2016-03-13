module Slnky
  module Service
    class Queues
      def initialize(channel)
        @channel = channel
        @queues = {}
      end

      def create(name, exchange, overrides={})
        options = {
            durable: true
        }.merge(overrides)
        @queues[name] = @channel.queue("service.#{@name}.events", options).bind(exchange)
      end

      def [](name)
        @queues["service.#{@name}.events"] || @queues[name] || raise("no queue found: #{name}")
      end

      def each
        @queues.each do |name, exchange|
          yield name, exchange
        end
      end
    end
  end
end
