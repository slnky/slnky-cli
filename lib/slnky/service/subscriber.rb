module Slnky
  module Service
    class << self
      def subscriber
        Slnky::Service::Subscriber.instance
      end
    end

    class Subscriber
      class << self
        def instance
          @instance ||= self.new
        end
      end

      def initialize
        @subscriptions = []
      end

      def handle(name, data)

      end

      def add(name, method)
        @subscriptions << Slnky::Service::Subscription.new(name, method)
      end

      def list
        @subscriptions
      end

      def each
        @subscriptions.each do |sub|
          yield sub.name, sub.method
        end
      end

      def for(name)
        @subscriptions.each do |sub|
          if sub.name == name || File.fnmatch(sub.name, name)
            yield sub.name, sub.method if block_given?
          end
        end
      end
    end

    class Subscription
      attr_reader :name
      attr_reader :method

      def initialize(name, method)
        @name = name
        @method = method
      end
    end
  end
end
