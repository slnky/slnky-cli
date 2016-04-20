module Slnky
  class << self
    def log
      Slnky::Log.instance
    end
  end

  class Log
    class << self
      def instance
        @logger ||= self.new
      end
    end

    attr_accessor :local
    attr_accessor :service
    attr_accessor :response

    def initialize
      @config = Slnky::Config.instance
      @env = @config.environment
      @response = false
      case @config.environment
        when 'production'
          @local   = false
          @service = Slnky::Log::Service.new
        when 'test'
          @local   = false
          @service = false
        else # development or unset
          @local   = Slnky::Log::Local.new
          @service = Slnky::Log::Service.new
      end
    end

    [:debug, :info, :warn, :error].each do |l|
      define_method(l) do |message|
        # bl = @local ? 'x' : 'o'
        # br = @remote ? 'x' : 'o'
        # bs = @response ? 'x' : 'o'
        # puts "#{l}:#{bl}#{br}#{bs} #{message}"
        log(l, message)
      end
    end

    private

    def log(level, message)
      @local.send(level, message) if @local
      @service.send(level, message) if @service
      @response.send(level, message) if @response
    end

    class Base
      [:debug, :info, :warn, :error].each do |l|
        define_method(l) do |message|
          log(l, message)
        end
      end

      protected

      def log(level, message)
        # override in subclass
      end
    end

    class False < Base

    end

    class Local < Base
      def initialize
        super
        @logger = ::Logger.new(STDOUT)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "%-5s %s: %s: %s\n" % [severity, datetime, Slnky::System.pid, msg]
        end
      end

      protected

      def log(level, message)
        @logger.send(level, message)
      end
    end

    class Service < Base
      # ex = @transport.exchanges['logs']
      # ex.publish(msg(data)) if ex # only log to the exchange if it's created
      # puts "%s [%6s] %s" % [Time.now, data[:level], data[:message]] if development? # log to the console if in development

      def initialize
        super
        @service = Slnky::System.pid
        @hostname = Slnky::System.hostname
        @ipaddress = Slnky::System.ipaddress
      end

      protected

      def log(level, message)
        return unless exchange
        data = {
            service: @service,
            level: level,
            hostname: @hostname,
            ipaddress: @ipaddress,
            message: message
        }
        exchange.publish(msg(data))
      end

      def transport
        @transport ||= Slnky::Transport.instance
      end

      def exchange
        @exchange ||= transport.exchanges['logs']
      end

      def msg(data)
        Slnky::Message.new(data)
      end
    end
  end
end
