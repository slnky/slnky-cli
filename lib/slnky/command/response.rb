module Slnky
  module Command
    class Response
      def initialize(channel, exchange, route, service)
        @channel = channel
        @exchange = exchange
        @route = route
        @service = service
      end

      def output(message)
        pub :info, message
      end

      def error(message)
        pub :error, message
      end

      def done!
        pub :complete, "complete"
      end

      private

      def msg(level, message)
        Slnky::Message.new({level: level, message: message, service: @service})
      end

      def pub(level, message)
        # puts "#{level} #{message}"
        @exchange.publish(msg(level, message), routing_key: @route)
      end
    end
  end
end
