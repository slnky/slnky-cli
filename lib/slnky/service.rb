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

      def initialize(url, options={})
        @server = url
        @name = self.class.name.split('::')[1].downcase
        @environment = options.delete(:environment) || 'development'
        @config = load_config(options)

        @transport = Slnky::Transport.setup(config)
        @subscriber = Slnky::Service.subscriber
        @timers = Slnky::Service.timers

        @command = "Slnky::#{@name.capitalize}::Command".constantize.new(config) rescue nil

        @server_down = false
      end

      def start
        @transport.start!(self) do |tx|
          log :info, "running"
          run

          @subscriber.add "slnky.#{@name}.command", :handle_command
          @subscriber.add "slnky.help.command", :handle_help
          @subscriber.add "slnky.service.restart", :handle_restart
          @timers.add 5.seconds, :handle_heartbeat

          @subscriber.each do |name, method|
            log :info, "subscribed to: #{name} -> #{self.class.name}.#{method}"
          end

          # @transport.queues[@name].subscribe do |raw|
          #   puts "raw: #{raw.inspect}"
          #   event = parse(raw)
          #   @subscriber.for(event.name) do |name, method|
          #     puts "#{name} #{method}"
          #     self.send(method.to_sym, event.name, event.payload)
          #   end
          # end
          #
          # @timers.each do |seconds, method|
          #   EventMachine.add_periodic_timer(seconds) do
          #     self.send(method.to_sym)
          #   end
          # end
        end
      end

      def handle_help(name, data)
        begin
          req = Slnky::Command::Request.new(data)
          res = Slnky::Command::Response.new(data.response, @name)
          @command.handle_help(req, res)
        rescue => e
          res.error "failed to run command: #{name}: #{data.command}"
          log :error, "failed to run command: #{name}: #{data.command}: #{e.message} at #{e.backtrace.first}"
        end
      end

      def handle_command(name, data)
        req = Slnky::Command::Request.new(data)
        res = Slnky::Command::Response.new(data.response, @name)
        return res.output "no command support for #{@name}" unless @command
        begin
          @command.handle(req, res)
        rescue => e
          res.error "failed to run command: #{name}: #{data.command}"
          log :error, "failed to run command: #{name}: #{data.command}: #{e.message} at #{e.backtrace.first}"
        end
        res.done!
      end

      def handle_restart(name, data)
        # if we get this event, just stop. upstart will start us again.
        log :warn, "received restart event"
        @transport.stop!('Restarted')
      end

      def handle_heartbeat
        return if @server_down
        Slnky.heartbeat(@server, @name)
      rescue => e
        log :info, "could not post heartbeat, server down? #{e.message}"
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

      def subscribe(name, method)
        raise 'move this to class level, use methods instead of blocks'
      end

      def periodic(seconds, method)
        raise 'move this to class level, use methods instead of blocks'
      end

      def log(level, message)
        data = {
            service: "#{@name}-#{$$}",
            level: level,
            hostname: Slnky::System.hostname,
            ipaddress: Slnky::System.ipaddress,
            message: message
        }
        ex = @transport.exchanges['logs']
        ex.publish(msg(data)) if ex # only log to the exchange if it's created
        puts "%s [%6s] %s" % [Time.now, data[:level], data[:message]] if development? # log to the console if in development
      end

      def development?
        @environment == 'development'
      end

      def load_config(config)
        # if you specify config, it will not load from server
        # this is useful for testing, so you won't need to be running
        # a server locally or configure your development service to
        # talk to production server
        if !config || config.count == 0
          config = Slnky.get_server_config(@server, @name)
        end
        DeepStruct.new(config)
      end

      class << self
        attr_reader :subscriptions
        attr_reader :periodics

        def subscribe(name, method)
          # @subscriptions ||= Slnky::Service::Subscriptions.new
          # @subscriptions.add(name, method)
          Slnky::Service.subscriber.add(name, method)
        end

        def periodic(seconds, method)
          # @periodics ||= Slnky::Service::Periodics.new
          # @periodics.add(seconds, method)
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
