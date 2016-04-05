module Slnky
  module Command
    class Response
      def initialize(route, service)
        @transport = Slnky::Transport.instance
        @channel = @transport.channel
        @exchange = @transport.exchanges['response']
        @route = route
        @service = Slnky::System.pid(service)
        start!
      end

      [:info, :warn, :error].each do |l|
        define_method(l) do |message|
          pub l, message
        end
      end

      def output(message)
        info(message)
      end

      def start!
        pub :start, "start"
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
