module Slnky
  module Command
    class Response
      attr_reader :trace

      def initialize(route, service)
        Slnky.config.service = service
        @route = route
        @service = Slnky::System.pid
        @started = false
        @trace = []
      end

      [:info, :warn, :error].each do |l|
        define_method(l) do |message|
          start! unless @started
          pub l, message
        end
      end

      def output(message)
        info(message)
      end

      def start!
        pub :start, "start"
        @started = true
      end

      def done!
        pub :complete, "complete"
      end

      def exchange=(exchange)
        @exchange = exchange
      end

      private

      def msg(level, message)
        Slnky::Message.new({level: level, message: message, service: @service})
      end

      def pub(level, message)
        # puts "#{level} #{message}"
        exchange.publish(msg(level, message), routing_key: @route)
        @trace << message
      end

      def config
        Slnky.config
      end

      def log
        Slnky.log
      end

      def exchange
        @exchange ||= transport.exchanges['response']
      end

      def transport
        @transport ||= Slnky::Transport.instance
      end

      def channel
        @channel ||= transport.channel
      end
    end
  end
end
