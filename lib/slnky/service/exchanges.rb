module Slnky
  module Service
    class Exchanges
      def initialize(channel)
        @channel = channel
        @exchanges = {}
      end

      def create(name, overrides={})
        options = {
            type: :fanout
        }.merge(overrides)
        @exchanges[name] =
            case options[:type]
              when :fanout
                @channel.fanout("slnky.#{name}")
              when :direct
                @channel.direct("slnky.#{name}")
              else
                raise "unknown exchange type: #{options[:type]}"
            end
      end

      def [](name)
        @exchanges["slnky.#{name}"] || @exchanges[name] || raise("no exchange found: #{name}")
      end

      def each
        @exchanges.each do |name, exchange|
          yield name, exchange
        end
      end
    end
  end
end
