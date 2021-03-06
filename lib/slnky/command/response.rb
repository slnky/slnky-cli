module Slnky
  module Command
    class Response
      attr_reader :trace

      def initialize(route, service)
        Slnky.config.service = service
        if route =~ /\:/
          (route, reply) = route.split(':', 2)
        end
        @route = route
        @reply = reply
        @service = Slnky::System.pid
        @started = false
        @exchange = nil
        @transport = nil
        @trace = []
      end

      [:debug, :info, :warn, :error].each do |l|
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
        Slnky::Message.new({level: level, message: message, service: @service, reply: @reply})
      end

      def pub(level, message)
        # if @route.to_s =~ /^hipchat/
        #   chat(level, message)
        # else
          exchange.publish(msg(level, message), routing_key: @route)
        # end
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
    end
  end
end
