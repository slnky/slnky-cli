module Slnky
  module Service
    class Subscriptions
      def initialize
        @subs = []
      end

      def add(name, method)
        @subs << {name: name, method: method}
      end

      def each
        @subs.each do |sub|
          yield sub[:name], sub[:method]
        end
      end

      def for(name)
        @subs.each do |sub|
          if sub[:name] == name || File.fnmatch(sub[:name], name)
            yield sub[:name], sub[:method] if block_given?
          end
        end
      end
    end
  end
end
