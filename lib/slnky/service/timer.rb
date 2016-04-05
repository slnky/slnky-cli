module Slnky
  module Service
    class << self
      def timers
        Slnky::Service::Timer.instance
      end
    end

    class Timer
      class << self
        def instance
          @instance ||= self.new
        end
      end

      def initialize
        @timers = []
      end

      def add(seconds, method)
        @timers << Slnky::Service::Periodic.new(seconds, method)
      end

      def list
        @timers
      end

      def each
        @timers.each do |t|
          yield t.seconds, t.method
        end
      end
    end

    class Periodic
      attr_reader :seconds
      attr_reader :method

      def initialize(seconds, method)
        @seconds = seconds
        @method = method
      end
    end
  end
end
