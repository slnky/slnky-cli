module Slnky
  module Service
    class Periodics
      def initialize
        @timers = []
      end

      def add(seconds, method)
        @timers << {seconds: seconds, method: method}
      end

      def each
        @timers.each do |timer|
          yield timer['seconds'], timer['method']
        end
      end
    end
  end
end
