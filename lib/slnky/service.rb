require 'slnky/version'
require 'slnky/message'
require 'slnky/service/subscriber'
require 'slnky/service/timer'

module Slnky
  module Service
    class Base
      attr_reader :config
      attr_reader :subscriber
      attr_reader :timers
      attr_reader :name

      def initialize
        @config = Slnky::Config.instance
        @server = @config.url
        @config.service = @name
        @environment = @config.environment

        @server_down = false
      end

      def name
        @name ||= self.class.name.split('::')[1].downcase
      end

      def transport
        @transport ||= Slnky::Transport.instance
      end

      def subscriber
        @subscriber ||= Slnky::Service.subscriber
      end

      def timers
        @timers ||= Slnky::Service.timers
      end

      def command
        @command ||= "Slnky::#{@name.capitalize}::Command".constantize.new rescue nil
      end

      def start
        transport.start!(self) do |_|
          log.info "running"
          run

          subscriber.add "slnky.#{@name}.command", :handle_command
          subscriber.add "slnky.help.command", :handle_command
          subscriber.add "slnky.service.restart", :handle_restart
          timers.add 5.seconds, :handle_heartbeat unless @config.development?

          subscriber.each do |name, method|
            log.info "subscribed to: #{name} -> #{self.class.name}.#{method}"
          end
        end
      end

      def handle_command(event, data)
        if command
          command.handle(event, data)
        else
          log.error "no comamnd support for #{@name}"
        end
      end

      def handle_restart(name, data)
        # if we get this event, just stop. upstart will start us again.
        log.warn "received restart event"
        transport.stop!('Restarted')
      end

      def handle_heartbeat
        return if @server_down
        Slnky.heartbeat(@server, @name)
      rescue => e
        log.info "could not post heartbeat, server down? #{e.message}"
        @server_down = true
      end

      protected

      def run
        # nothing here - overridden in subclasses
      end

      def msg(data)
        Slnky::Message.new(data)
      end

      def parse(data)
        Slnky::Message.parse(data)
      end

      def log
        @log ||= Slnky::Log.instance
      end

      def development?
        @environment == 'development'
      end

      class << self
        def subscribe(name, method)
          Slnky::Service.subscriber.add(name, method)
        end

        def periodic(seconds, method)
          Slnky::Service.timers.add(seconds, method)
        end
        alias_method :timer, :periodic
      end

      # def pub(data)
      #   if block_given?
      #     @exchange.publish(msg(data)) do
      #       yield
      #     end
      #   else
      #     @exchange.publish(msg(data))
      #   end
      # end
    end
  end
end
