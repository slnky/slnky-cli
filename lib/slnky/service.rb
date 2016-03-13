require 'amqp'
require 'open-uri'
require 'json'
require 'socket'

require 'slnky/version'
require 'slnky/message'
require 'slnky/service/subscriptions'
require 'slnky/service/periodics'
require 'slnky/service/queues'
require 'slnky/service/exchanges'

module Slnky
  module Service
    class Base
      attr_reader :config

      def initialize(url, options={})
        @server = url
        @name = self.class.name.split('::').last.downcase
        @environment = options.delete(:env) || options.delete(:environment) || 'development'
        @config = load_config(options)

        @subscriptions = self.class.subscriptions || Slnky::Service::Subscriptions.new
        @periodics = self.class.periodics || Slnky::Service::Periodics.new
        @hostname = Socket.gethostname
        @ipaddress = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
      end

      def start
        AMQP.start("amqp://#{config.rabbit.host}:#{config.rabbit.port}") do |connection|
          @channel = AMQP::Channel.new(connection)
          @channel.on_error do |ch, channel_close|
            raise "Channel-level exception: #{channel_close.reply_text}"
          end

          @exchanges = Slnky::Service::Exchanges.new(@channel)
          @exchanges.create('events')
          @exchanges.create('logs')

          @queues = Slnky::Service::Queues.new(@channel)
          @queues.create(@name, @exchanges['events'])

          log :info, "running"

          run

          @subscriptions.each do |name, method|
            log :info, "subscribed to: #{name} -> #{self.class.name}.#{method}"
          end

          @queues[@name].subscribe do |raw|
            message = parse(raw)
            event = message.name
            data = message.payload
            @subscriptions.for(event) do |name, method|
              self.send(method.to_sym, event, data)
            end
          end

          @periodics.each do |seconds, method|
            EventMachine.add_periodic_timer(seconds) do
              self.send(method.to_sym)
            end
          end

          stopper = Proc.new do
            puts 'stopping'
            # TODO: log :warn, "slnky.service.#{@name}: stopping"
            connection.close { EventMachine.stop }
          end

          Signal.trap("INT", stopper)
          Signal.trap("TERM", stopper)
        end
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
        raise "move this to class level, use methods instead of blocks"
        # @subscriptions.add(name, method)
      end

      def periodic(seconds, method)
        raise "move this to class level, use methods instead of blocks"
        # @periodics.add(seconds, method)
      end

      def log(level, message)
        data = {
            service: "#{@name}-#{$$}",
            level: level,
            hostname: @hostname,
            ipaddress: @ipaddress,
            message: "slnky.service.#{@name}: #{message}"
        }
        @exchanges['logs'].publish(msg(data)) if @exchanges && @exchanges['logs'] # only log to the exchange if it's created
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
          config = JSON.parse(open("#{@server}/configs/#{@name}") {|f| f.read })
        end
        DeepStruct.new(config)
      end

      class << self
        attr_reader :subscriptions
        attr_reader :periodics

        def subscribe(name, method)
          @subscriptions ||= Slnky::Service::Subscriptions.new
          @subscriptions.add(name, method)
        end

        def periodic(seconds, method)
          @periodics ||= Slnky::Service::Periodics.new
          @periodics.add(seconds, method)
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
